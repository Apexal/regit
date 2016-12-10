module Regit
  module Commands
    module WhoIs
      extend Discordrb::Commands::CommandContainer

      command(:whois, description: 'Show description.') do |event|
        target = (event.message.mentions.empty? ? event.author : event.message.mentions.first.on(event.server))
        if target.student?
          "*#{target.display_name}* is **#{event.author.info.first_name} #{event.author.info.last_name}**"
        else
          "*#{target.display_name}* is not a student."
        end
      end
    end
  end
end