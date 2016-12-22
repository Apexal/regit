module Regit
  module Events
    
    module VoiceState
      extend Discordrb::EventContainer

      def self.simplify_voice_states(voice_states)
        simple = {}

        voice_states.each do |user_id, state|
          simple[user_id] = state.voice_channel
        end

        return simple
      end

      voice_state_update do |event|
        LOGGER.info 'USER STATE UPDATE'
        
        old = OLD_VOICE_STATES[event.server.id]
        states = simplify_voice_states(event.server.voice_states)

        if old != states
          LOGGER.info "Person moved..."
          # Person changed voice-channel
          # How?
          if old[event.user.id].nil?
            # Connected to voice
            LOGGER.info "#{event.user.distinct} joined #{states[event.user.id].name}"
          elsif states[event.user.id].nil?
            # Disconnected from voice
            LOGGER.info "#{event.user.distinct} disconnected from #{old[event.user.id].name}"
          else
            # Changed rooms
            LOGGER.info "#{event.user.distinct} moved from #{old[event.user.id].name} to #{states[event.user.id].name}"
          end
        end

        OLD_VOICE_STATES[event.server.id] = states.clone
      end
    end
  end
end