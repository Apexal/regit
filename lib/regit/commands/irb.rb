# Example command module

module Regit
  module Commands
    module IrbCommand
      extend Discordrb::Commands::CommandContainer

      command(:irb, description: 'Open console.') do |event|
        IRB.start
      end
    end
  end
end