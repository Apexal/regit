# Example command module

module Regit
  module Commands
    module Rename
      extend Discordrb::Commands::CommandContainer

      command(:rename, description: 'Change name of a voice room.', permission_level: 1, min_args: 0, max_args: 1) do |event, new_name|
        event.message.delete unless event.channel.private?
        
        # Check if in #voice-channel
        unless event.channel.association == :voice_channel
          event.channel.send_temporary_message("You can must use this in #{event.user.voice_channel.associated_channel.mention}!", 5) unless event.user.voice_channel.nil?
          return
        end

        voice_channel = event.channel.associated_channel
        return nil if voice_channel.nil?

        # Validate new_name
        # max_length = 100
        new_name.strip!
        
        max_length = 100 - 'Room '.length # 95; easy to change later on
        new_name = new_name[0..max_length-1]

        voice_channel.name = "Room #{new_name}"
        event.channel.topic = "Private chat for all those in the voice-channel **#{voice_channel.name}**."

        "**#{event.user.display_name}** renamed room to **Room #{new_name}**."
      end
    end
  end
end