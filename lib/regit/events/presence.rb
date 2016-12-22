module Regit
  module Events
    module Presence
      extend Discordrb::EventContainer

      def self.update_grade_voice_channels(server)
        
      end

      presence do |event|
        LOGGER.debug "#{event.user.distinct} is now #{event.user.status} on #{event.server.name}"
      end
    end
  end
end