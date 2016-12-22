# Example command module

module Regit
  module Commands
    module IrbCommand
      extend Discordrb::Commands::CommandContainer

      command(:irb, description: 'Open console.') do |event|
        binding.pry
      end
    end
  end
end