module Regit
  module Events
    module Presence
      extend Discordrb::EventContainer

      member_join do |event|
        LOGGER.info "#{event.user.distinct} HAS JOINED SERVER #{event.server.name}"
        event.server.owner.pm "#{event.user.mention} HAS JOINED THE SERVER"
      end

      member_leave do |event|
        LOGGER.info "#{event.user.distinct} HAS LEFT SERVER #{event.server.name}"
        event.server.owner.pm "#{event.user.mention} HAS LEFT THE SERVER"
      end

      presence do |event|
        Regit::Schedule::update_work_channel_topic() if event.user.status == :online

        LOGGER.info "#{event.user.distinct} is now #{event.user.status} on #{event.server.name}"

        begin;Regit::Database::Student.find_by_discord_id(event.user.id).update(last_online: Time.new) if event.user.status == :offline;rescue;end
      end
    end
  end
end