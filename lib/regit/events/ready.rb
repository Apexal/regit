module Regit
  module Events
    # Notifies user that bot is ready to use.
    module Ready
      extend Discordrb::EventContainer
      ready do |event|
        BOT.game = 'with the Future'
        LOGGER.info 'Regit is ready.'

        # Set up voice states already
        event.bot.servers.each do |server_id, server|
          Regit::OLD_VOICE_STATES[server_id] = Regit::Events::VoiceState::simplify_voice_states(server.voice_states)
        end
      end
    end
  end
end