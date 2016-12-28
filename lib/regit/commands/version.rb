# Example command module

module Regit
  module Commands
    module Version
      extend Discordrb::Commands::CommandContainer

      command(:version, description: 'Show description.') do |event|
        "**Regit** **v#{Regit::VERSION}**  |  created by Frank Matranga <https://github.com/Apexal/regit>"
      end
    end
  end
end