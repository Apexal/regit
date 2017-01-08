module Regit
  module Events
    module Presence
      extend Discordrb::EventContainer

      presence do |event|
        LOGGER.info "#{event.user.distinct} is now #{event.user.status} on #{event.server.name}"

        begin;Regit::Database::Student.find_by_discord_id(event.user.id).update(last_online: Time.new) if event.user.status == :offline;rescue;end
      end
    end
  end
end