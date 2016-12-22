# Example command module

module Regit
  module Commands
    module Version
      extend Discordrb::Commands::CommandContainer

      command(:version, description: 'Show description.') do |event|
        c_id = event.channel.id
        group = event.server.school.groups.first
        
        #"**Regit** **v#{Regit::VERSION}**  |  created by Frank Matranga <https://github.com/Apexal/regit>"
      end
    end
  end
end