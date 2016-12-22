module Regit
  module Events
    # Notifies user that bot is ready to use.
    module NewServer
      extend Discordrb::EventContainer
      server_create do
        if event.server.setup?

        else
          LOGGER.info "BOT ADDED TO NEW SERVER: #{event.server.name}"
          event.server.owner.pm '**Regit** has been added to your server. To set everything up, please type `!setup`.'
        end
      end
    end
  end
end