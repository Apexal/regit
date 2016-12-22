# Example command module

module Regit
  module Commands
    module Groups
      extend Discordrb::Commands::CommandContainer

      command(:groups, max_args: 0, description: 'List all open groups for this server.', usage: '`!groups`') do |event|
        event.message.delete unless event.channel.private?
        if event.channel.private?
          event.user.pm 'You can only use `!groups` in a school server!'
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

        new_group = Regit::Groups::create_group(event.user.on(event.server), full_name, description, (is_private == 'yes' || is_private == '1' || is_private == 'true' ))
        
        if new_group.nil?
          event.user.pm 'Groups already exists!'
        end

        event.user.pm "You have created the Group **#{full_name}**."
        nil
      end
    end
  end
end