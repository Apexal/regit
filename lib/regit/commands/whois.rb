module Regit
  module Commands
    module WhoIs
      extend Discordrb::Commands::CommandContainer

      command(:whois, description: 'Show description.') do |event|
        target = (event.message.mentions.empty? ? event.author : event.message.mentions.first.on(event.server))
        if target.student?(event.server.school)
          "**#{event.author.info.first_name} #{event.author.info.last_name}** of **3A-2** | *#{event.author.info.email}*"
        elsif target.guest?(event.server.school)
          "*#{target.display_name}* is a guest from **#{target.info.school.title} #{target.info.school.school_type}**!"
        elsif target == event.server.owner
          "That is the owner of the server!"
        else
          "*#{target.display_name}* is not a student."
        end
      end
    end
  end
end