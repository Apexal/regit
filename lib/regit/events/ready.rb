module Regit
  module Events
    # Notifies user that bot is ready to use.
    module Ready
      extend Discordrb::EventContainer
      ready do
        BOT.game = 'with the Future'
        LOGGER.info 'Regit is ready.'
      end
    end
  end
end