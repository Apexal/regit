# Example command module

module Regit
  module Commands
    module Administration
      extend Discordrb::Commands::CommandContainer

      command(:stop, description: 'Shutdown bot.') do |event|
        save_associations
        Regit::BOT.stop
      end
    end
  end
end