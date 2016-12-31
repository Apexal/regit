# Example command module

module Regit
  module Commands
    module Administration
      extend Discordrb::Commands::CommandContainer

      command(:stop, description: 'Shutdown bot.', permission_level: 3) do |event|
        Regit::BOT.stop
      end
    end
  end
end