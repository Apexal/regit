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

      # This command deletes all course channels currently open, removes advisement roles and rooms, and sets summer mode to true
      command(:summer, description: 'Enter a server into summer mode by removing traces of school!', permission_level: 3) do |event|
        
      end
    end
  end
end