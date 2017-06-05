module Regit
  module Groups
    INVITES = {}
    # {
    #   user_id: [group_id, group_id],
    #   user_id: [group_id] 
    # }

    def self.ensure_connections(server)
      begin
        server.school.groups.each do |g|
          # Check if channel exists
          owner = g.owner
          owner = owner.on(server) unless owner.nil?

          if g.role.nil?
            group_role = create_group_role(server, owner, g.name)
            g.update(role_id: group_role.id)
          end

          if g.text_channel.nil?
            LOGGER.info "text-channel for Group #{g.name} doesn't exist!!! Fixing..."
            channel_name = g.name.dup
            channel_name.downcase!
            channel_name.gsub!(/\s+/, '-')
            channel_name.gsub!(/[^\p{Alnum}-]/, '')
            group_text_channel = create_group_channel(server, owner, g.role, channel_name, g.description)
            g.update(text_channel_id: group_text_channel.id)
          end
        end
      rescue => e
        LOGGER.error e.backtrace.join("\n\t")
      end
    end

    def self.group_embed(group)
      Discordrb::Webhooks.Builder.new.add_embed do |embed|
        embed.title 'Test'
      end
    end

    def self.delete_group(id)
      group = Regit::Database::Group.find(id)

      # SO EZ
      group.school.server.members.select { |m| m.role? group.role }.each { |m| m.pm "**Group #{group.name}** has been deleted." }
      group.role.delete
      group.text_channel.delete

      LOGGER.info "Deleted group #{group.name} of #{group.school.title} server"
      group.destroy
    end

    def self.create_group_role(server, owner, role_name)
      # Create role
      group_role = server.create_role
      group_role.name = role_name
      group_role.mentionable = true
      owner.add_role(group_role) unless owner.nil?

      group_role
    end

    def self.create_group_voice_channel(group)
      server = group.school.server

      # Make sure it's allowed
      raise 'This group is not allowed to have a voice-channel.' unless group.voice_channel_allowed

      # Ensure voice-channel isn't already open
      raise "A voice-channel for **Group #{group.name}** already is open!" unless server.voice_channels.find { |vc| vc.name == "Group #{group.name}" }.nil?

      channel = server.create_channel("Group #{group.name}", 2) # Create voice-channel
      channel.limit = group.members.length
      channel.position = server.voice_channels.find { |vc| vc.name == '[New Room]' }.position - 1

      perms = Discordrb::Permissions.new
      perms.can_connect = true

      channel.define_overwrite(server.server_role, 0, perms)
      channel.define_overwrite(group.role, perms, 0)

      channel
    end

    def self.create_group_channel(server, owner, group_role, channel_name, description)
      # Perms for group members
      group_perms = Discordrb::Permissions.new
      group_perms.can_read_messages = true
      group_perms.can_read_message_history = true
      group_perms.can_send_messages = true
      group_perms.can_mention_everyone = true

      # Perms for non-group members
      non_perms = Discordrb::Permissions.new
      non_perms.can_read_messages = true

      # Group owner perms
      owner_perms = Discordrb::Permissions.new
      owner_perms.can_manage_messages = true

      # Create text-channel
      group_text_channel = server.create_channel(channel_name, 0)
      group_text_channel.topic = "**Group #{group_role.name}** | #{description}" + (owner.nil? ? '' : " | Owned by #{owner.mention}")
      group_text_channel.define_overwrite(group_role, group_perms, 0) # Allow group members to use it
      group_text_channel.define_overwrite(owner, owner_perms, 0) unless owner.nil? # Add owner perms 
      group_text_channel.define_overwrite(server.roles.find { |r| r.id == server.id }, 0, non_perms) # Don't allow anyone else

      group_text_channel
    end

    def self.create_group(owner, full_name, description, is_private)
      full_name.strip!
      raise 'Empty group name!' if full_name.empty?

      server = owner.server

      # Prepare data
      full_name = full_name[0..20]

      raise 'Group name must start with a letter' if full_name.start_with? '#'

      # Check if already exists
      raise "Group #{full_name} already exists!" if Regit::Database::Group.where(name: full_name).count > 0

      # Check if same name as role
      raise 'Invalid group name!' unless server.roles.find { |r| r.name.downcase == full_name.downcase }.nil? 

      description = description.empty? ? 'No description given.' : description[0..254]
      group_name = full_name.dup
      group_name.downcase!
      group_name.gsub!(/\s+/, '-')
      group_name.gsub!(/[^\p{Alnum}-]/, '')

      raise "Group name '#{full_name}' is too short!" if group_name.length < 3

      # In case some wise-guy tries to create a group called "work"
      raise 'Invalid group name!' unless server.text_channels.find { |t| t.name == group_name }.nil?

      group_role = create_group_role(server, owner, full_name)
      group_text_channel = create_group_channel(server, owner, group_role, group_name, description)

      LOGGER.info "Attempting to create group '#{group_name}'"
      group = Regit::Database::Group.create(school_id: server.school.id, name: full_name, private: is_private, owner_username: owner.info.username, description: description, default_group: false, text_channel_id: group_text_channel.id, role_id: group_role.id, voice_channel_allowed: true)
      return group
    end

    def self.add_invite(target, group_id)
      raise 'Not a school member!' unless target.student?(target.server.school)

      INVITES[target.id] ||= []
      INVITES[target.id] << group_id
    end

    def self.remove_invite(target, group_id)
      raise 'Not a school member!' unless target.student?(target.server.school)

      INVITES[target.id].delete(group_id)
      INVITES.delete(target.id) if INVITES[target.id].empty? 
      INVITES[target.id]
    end

    def self.add_to_group(member, group_id)
      raise 'Not a school member!' unless member.student?(member.server.school)
      group = Regit::Database::Group.find(group_id)
      raise "Group #{group_id} doesn't exist!" if group.nil?
      
      begin;Regit::LOGGER.info "Adding #{member.distinct} to Group #{group.name}";rescue;end
      
      member.add_role(group.role)

      group
    end

    def self.remove_from_group(member, group_id)
      raise 'Not a school member!' unless member.student?(member.server.school)

      group = Regit::Database::Group.find(group_id)
      raise 'Group doesn\'t exist!' if group.nil?

      raise 'Not in that group.' unless member.role? group.role

      group.text_channel.send_message "*#{member.mention} left the group.*"
      member.remove_role group.role

      return group
    end

  end
end