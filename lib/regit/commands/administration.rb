# Commands for the Consul

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
        return event.user.pm('It\'s not summer yet!') unless Regit::School::summer?(event.server.school)

        Regit::School::close_course_channels(event.server)
        Regit::School::remove_advisement_channels(event.server)
        Regit::School::remove_advisement_roles(event.server)

        'Hello summer.'
      end
    end
  end
end