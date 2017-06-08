# Example command module

module Regit
  module Commands
    module Groups
      extend Discordrb::Commands::CommandContainer

      command(:groups, max_args: 0, description: 'List all open groups for this server.', usage: '`!groups`', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event|
        event.message.delete unless event.channel.private?
				
        groups = Regit::Database::Group.where(school_id: event.server.school.id).order(name: :asc)
        messages = []
        messages << ":school: __**PUBLIC GROUPS FOR #{event.server.name} (#{event.server.school.title} #{event.server.school.school_type})**__ :school: "

        groups.each do |g|
          messages << ("**#{g.name}** `#{g.description}`" + (g.owner_username.nil? ? '' : "(#{g.owner_username})"))
        end

        messages << "\n *#{groups.count} total*"

        event.user.pm.split_send(messages.join("\n"))

        nil
      end

      command(:creategroup, min_args: 2, max_args: 3, description: 'Create a private group for some member!', usage: '`!creategroup "Name" "Description"`', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event, full_name, description, is_private|
        event.message.delete unless event.channel.private?

        begin
          new_group = Regit::Groups::create_group(event.user.on(event.server), full_name, description, (is_private == 'yes' || is_private == '1' || is_private == 'true' ))
          event.user.pm "You have created the Group **#{full_name}**. You now have access to `##{new_group.text_channel.name}`. Use your group page at http://www.getontrac.info:4567/groups/#{new_group.id} to manage it."
          
          # TODO: send embed
          Regit::Utilities::announce(event.server, "#{event.user.mention} has created public **Group #{new_group.name}**!") unless new_group.private?
        rescue => e
          event.user.pm "Failed to create group: #{e}"
          LOGGER.error "Failed to create group: #{e}"
          LOGGER.error e.backtrace.join("\n")
          Regit::Utilities::clean_channels(event.server)
        end

        nil
      end

      # Delete a group and notify all the members
      command(:deletegroup, max_args: 0, description: 'Delete a group you own.', usage: '`!deletegroup` in a group\'s text channel', permission_level: 1) do |event|
        event.message.delete unless event.channel.private?

        user = event.user.on(event.server)

        begin
          raise 'Not in a group text channel!' unless event.channel.association == :group
          group = Regit::Database::Group.find_by_text_channel_id(event.channel.id)
          name = group.name

          raise 'This is a protected group!' if ['Meta', 'Memes', 'Recreation', 'Gaming', 'Politics', 'Testing'].include? name

          raise 'You do not own this group!' unless group.owner.on(event.server) == user || user.moderator?

          Regit::Groups::delete_group(group.id)

          event.user.pm("You have deleted **Group #{name}**")
        rescue => e
          LOGGER.error "Failed to delete group: #{e}"
          LOGGER.error e.backtrace.join("\n")
          event.user.pm("Failed to delete group: #{e}")
          Regit::Utilities::clean_channels(event.server)
        end

        nil
      end

      # Allows a member of a private group to invite somebody else to the group, allowing them to join
      command(:invite, min_args: 2, max_args: 2, description: 'Invite a student to a private group.', usage: '`!invite "Group" @member`', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event, group_name|
        event.message.delete unless event.channel.private?

        user = event.user.on(event.server)

        group_name.strip!

        return event.user.pm 'Usage: `!invite "Group" @member`' if event.message.mentions.empty?

        target = event.message.mentions.first.on(event.server)

        begin
          raise 'Invalid group name' if group_name.empty?
          group = Regit::Database::Group.find_by_name(group_name)
          raise 'Could not find group.' if group.nil?
          raise 'You aren\'t in that group!' unless user.role?(group.role)
          raise 'Group is not private!' unless group.private?
          raise 'Target is already in that group!' if target.role?(group.role)

          Regit::Groups::add_invite(target, group.id)

          target.pm("You've been invited to private **Group #{group.name}** by member #{user.mention} (#{user.short_info}).\nJoin with `!join \"#{group.name}\"` on the server!")
          user.pm("Invited #{target.mention} to private **Group #{group.name}**. They can now join with `!join \"#{group.name}\"`")
        rescue => e
          event.user.pm "Failed to invite: #{e}"
          LOGGER.error "Failed to invite: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end

        nil
      end

      # Create private voice-channels for special situations
      command(:vc, description: 'Create a temporary voice channel for a group or course.', min_args: 0, max_args: 0, permission_level: 1) do |event|
        event.message.delete unless event.channel.private?

        # Ensure in group channel or course
        return event.user.pm('`!vc` must be used in a group, course, or advisement\'s text-channel!') unless [:group, :course, :advisement].include? event.channel.association

        if event.channel.association == :group
          group = Regit::Database::Group.find_by_text_channel_id(event.channel.id)
          return if group.nil?

          begin
            Regit::Groups::create_group_voice_channel(group)
          rescue => e
            return event.user.pm "Failed to create special voice-channel: #{e}"
          end

          return event.channel.send_message('A **private** temporary voice-channel for this group has been opened! It will disappear when empty.')
        elsif event.channel.association == :advisement
          advisement = event.channel.name.upcase

          # Create Advisement Room (same as normal opened room)
          v_perms = Discordrb::Permissions.new
          v_perms.can_connect = true

          # Make sure doesn't exist
          return event.channel.send_temporary_message('An advisement voice room already exists!', 5) unless event.server.voice_channels.find { |vc| vc.name == "Advisement #{advisement}" }.nil?

          channel = event.server.create_channel("Advisement #{advisement}", 2)

          # Allow only one advisement entry
          adv_role = event.server.roles.find { |r| r.name == advisement }
          channel.define_overwrite(adv_role, v_perms, 0) # Advisement
          channel.define_overwrite(event.server.roles.find { |r| r.id == event.server.id }, 0, v_perms) # @everyone
          # channel.user_limit = adv_role.members.length

          # Move user in if in voice
          event.server.move(event.user, channel) unless event.user.voice_channel.nil?

          return event.channel.send_message("@everyone Join **Advisement #{advisement}** to for a private chat! (Opened by #{event.user.mention})")
        else
          # Make sure user is in studymode
          # return event.user.pm('You must be in `!study`mode to open a course study room.') unless event.user.studying?

          course = Regit::Database::Course.where(school_id: event.server.school.id, text_channel_id: event.channel.id).first
          course_name = "#{course.teacher.last_name} #{Regit::Registration::course_name(course.title)} Study Room"

          # Make sure doesn't exist
          return event.channel.send_temporary_message('A study voice room already exists!', 5) unless event.server.voice_channels.find { |vc| vc.name == course_name }.nil?

          # Create Study Room (same as normal opened room)
          v_perms = Discordrb::Permissions.new
          v_perms.can_connect = true

          channel = event.server.create_channel(course_name, 2)
          # channel.define_overwrite(event.server.roles.find { |r| r.name == 'Studying' }, v_perms, 0)

          # Allow only one grade-level entry
          channel.define_overwrite(event.server.roles.find { |r| r.name == event.user.info.grade_name }, v_perms, 0)
          channel.define_overwrite(event.server.roles.find { |r| r.id == event.server.id }, 0, v_perms)

          # Move user in if in voice
          event.server.move(event.user, channel) unless event.user.voice_channel.nil?

          return event.channel.send_message("@everyone **Join `#{course_name}` to group study #{course.title}!**")
        end

        nil
      end

      # Join a group
      command(:join, max_args: 1, description: 'Join a group.', usage: '`!join "Group Name"`', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event, group_name|
        event.message.delete unless event.channel.private?

        user = event.user.on(event.server)

        begin
          raise 'No group name given!' if group_name.nil?

          group = Regit::Database::Group.where('lower(name) = ?', group_name.downcase).first
          raise 'Doesn\'t exist!' if group.nil?

          if group.private? && !user.moderator?
            invites = Regit::Groups::INVITES[event.user.id]
            raise 'You have not been invited to that private group!' if invites.nil? || !invites.include?(group.id)
          end

          Regit::Groups::add_to_group(event.user, group.id)

          group.text_channel.send_message "#{user.short_info(true)} joined the group."
          event.user.pm("Joined group! | http://www.getontrac.info:4567/groups/#{group.id}")
        rescue => e
          event.user.pm("Failed to join group: #{e}")
          LOGGER.error "Failed to join group: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end

        nil
      end

      command(:leave, max_args: 0, description: 'Leave a group.', usage: '`!leave` in a group text-channel', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event|
        event.message.delete unless event.channel.private?
        
        user = event.user.on(event.server)

        begin
          group = Regit::Groups::remove_from_group(user, Regit::Database::Group.find_by_text_channel_id(event.channel.id).id)
          group.text_channel.send_message("#{user.short_info(true)} left the group.")

          if event.server.students.count { |m| m.role? group.role } == 0
            # Delete group when everybody leaves
            Regit::Groups::delete_group(group.id)
          end

          user.pm 'Left group!'
        rescue => e
          user.pm "Failed to leave group: #{e}"
          LOGGER.error "Failed to leave group: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end

        nil
      end

      # For group owners and Moderators
      command(:gkick, max_args: 1, description: 'Kick a student from a group.', usage: '!gkick @user in a group text-channel', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event|
        event.message.delete unless event.channel.private?
        
        user = event.user.on(event.server)
        target = event.message.mentions.first
        group = Regit::Database::Group.find_by_text_channel_id(event.channel.id)

        begin
          raise 'You must use this in a group text-channel.' if group.nil?
          raise 'Only the owner of this group and moderators can kick users!' unless group.owner == user || user.moderator?
          raise 'Need to mention user to kick!' if target.nil?
          raise 'Can\'t kick yourself!' if user == target

          target = target.on(event.server)

          group = Regit::Groups::remove_from_group(target, group.id)
          group.text_channel.send_message("#{target.short_info(true)} was kicked from the group.")

          target.pm("You were kicked from **Group #{group.name}**.")
          user.pm("Kicked #{target.short_info(true)} from **Group #{group.name}**.")
        rescue => e
          user.pm "Failed to kick user from group: #{e}"
          LOGGER.error "Failed to kick user from group: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end

        nil
      end

    end
  end
end