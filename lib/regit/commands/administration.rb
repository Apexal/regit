# Example command module

module Regit
  module Commands
    module Administration
      extend Discordrb::Commands::CommandContainer

      command(:stop, description: 'Shutdown bot.', permission_level: 3) do |event|
        Regit::BOT.stop
      end

      command(:site, description: 'Show link to website.', permission_level: 1) do |event|
        "http://www.getontrac.info:4567/"
      end
    end
  end
end