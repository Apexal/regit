module Regit
  module Events
    module React
      extend Discordrb::EventContainer

      reaction_add(emoji: "☑") do |event|
        next unless event.channel.name == 'groups'

        next if event.message.embeds.empty?
        group_name = event.message.embeds.first.title.sub('Group ', '')

        group = Regit::Database::Group.find_by_name(group_name)
        next if group.nil?

        server = event.channel.server
        user = event.user.on(server)

        next if user.role?(group.role)

        begin
          if group.private? && !user.moderator?
            invites = Regit::Groups::INVITES[user.id]
            raise 'You have not been invited to that private group!' if invites.nil? || !invites.include?(group.id)
          end

          Regit::Groups::add_to_group(user, group.id)

          group.text_channel.send_message "#{user.short_info(true)} joined the group."
          # event.user.pm("Joined group! | http://www.getontrac.info:4567/groups/#{group.id}")
        rescue => e
          event.user.pm("Failed to join group: #{e}")
          LOGGER.error "Failed to join group: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end

      end


      reaction_remove(emoji: "☑") do |event|
        next unless event.channel.name == 'groups'

        next if event.message.embeds.empty?
        group_name = event.message.embeds.first.title.sub('Group ', '')

        group = Regit::Database::Group.find_by_name(group_name)
        next if group.nil?

        server = event.channel.server
        user = event.user.on(server)

        next unless user.role?(group.role)

        begin
          group = Regit::Groups::remove_from_group(user, group.id)
          group.text_channel.send_message("#{user.short_info(true)} left the group.")

          if group.members.empty?
            # Delete group when everybody leaves
            Regit::Groups::delete_group(group.id)
          end

          user.pm 'Left group!'
        rescue => e
          user.pm "Failed to leave group: #{e}"
          LOGGER.error "Failed to leave group: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end

      end

    end
  end
end
