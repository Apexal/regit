module Regit
  module Events
    module VoiceState
      extend Discordrb::EventContainer

      # Voice channel created
      channel_create(type: 2, name: not!(Regit::CONFIG.new_room_name)) do |event|
        Regit::VoiceChannels::associate_voice_channel(event.channel)
      end

      # Voice channel deleted
      channel_delete(type: 2) do |event|
        begin
          CHANNEL_OWNERS[event.server.id].delete event.id
          event.server.text_channels.find { |tc| tc.id == CHANNEL_ASSOCIATIONS[event.server.id][event.id] }.delete
        rescue => e
          LOGGER.info 'Failed to remove associated channel on vc delete: '
          LOGGER.error e
        end

        Regit::VoiceChannels::trim_voice_associations(event.server)
      end

      # Remove existing votekicks
      channel_delete(type: 0) do |event|
        VOTEKICKS[event.server.id].delete event.id
      end

      voice_state_update do |event|
        member = event.user.on(event.server)

        if event.old_channel != event.channel
          # Something has happened
          Regit::VoiceChannels::handle_user_change(:leave, event.old_channel, member) unless event.old_channel.nil?
          Regit::VoiceChannels::handle_user_change(:join, event.channel, member) unless event.channel.nil?
        end
      end
    end
  end
end