module Regit
  module Events
    module Presence
      extend Discordrb::EventContainer

      presence do |event|
        LOGGER.info "#{event.user.distinct} is now #{event.user.status} on #{event.server.name}"
      end
    end
  end
end