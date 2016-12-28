# Example command module

module Regit
  module Commands
    module Groups
      extend Discordrb::Commands::CommandContainer

      command(:groups, max_args: 0, description: 'List all open groups for this server.', usage: '`!groups`') do |event|
        event.message.delete unless event.channel.private?
        if event.channel.private?
          event.user.pm 'You can only use `!groups` on a school server!'
          return
        end

        groups = Regit::Database::Group.where(school_id: event.server.school.id).order(name: :asc)
        messages = []
        messages << ":school: __**PUBLIC GROUPS FOR #{event.server.name} (#{event.server.school.title} #{event.server.school.school_type})**__ :school: "

        groups.each do |g|
          messages << "**#{g.name}** `#{g.description}` (#{g.owner_username})"
        end

        messages << "\n *#{groups.count} total*"

        event.user.pm.split_send(messages.join("\n"))

        nil
      end

      command(:creategroup, min_args: 2, max_args: 3, description: 'Create a private group for some member!', usage: '`!creategroup "Name" "Description"`') do |event, full_name, description, is_private|
        event.message.delete unless event.channel.private?
        
        if event.channel.private?
          event.user.pm 'You can only use `!creategroup` on a school server!'
          return
        end

        begin
          new_group = Regit::Groups::create_group(event.user.on(event.server), full_name, description, (is_private == 'yes' || is_private == '1' || is_private == 'true' ))
          event.user.pm "You have created the Group **#{full_name}**. You now have access to `##{new_group.text_channel.name}`."
          
          # TODO: send embed
          Regit::Utilities::announce(event.server, "#{event.user.mention} has created public **Group #{new_group.name}**!") unless new_group.private?

        rescue => e
          event.user.pm "Failed to create group: #{e}"
          Regit::Utilities::clean_channels(event.server)
        end

        nil
      end

      command(:leave, max_args: 0, description: 'Leave a group.', usage: '`!leave` in a group text-channel') do |event|
        event.message.delete unless event.channel.private?
        
        if event.channel.private? || event.channel.association != :group
          event.user.pm 'You can only use `!leave` on a group text-channel!'
          return
        end

        begin
          group = Regit::Groups::remove_from_group(event.user, Regit::Database::Group.find_by_text_channel_id(event.channel.id).id)
          if event.server.members.count { |m| m.role? group.role } == 0
            # Delete group when everybody leaves
            Regit::Groups::delete_group(group.id)
          end
          event.user.pm 'Left group!'
        rescue => e
          event.user.pm "Failed to leave group: #{e}"
          p e.backtrace
        end
      end
    end
  end
end