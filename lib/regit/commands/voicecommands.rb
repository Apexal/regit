# Example command module

module Regit
  module Commands
    module VoiceCommands
      extend Discordrb::Commands::CommandContainer
			
      # Allow voice-channel owners to ban people from the channel
			command(:vban, description: 'Toggle ban of unwanted users from a voice-channel.', permission_level: 1, usage: '`!vban @user`') do |event|
				event.message.delete unless event.channel.private?
				
        user = event.user.on(event.server)
        vc = event.channel.associated_channel

        begin
          raise 'You must give 1 user to toggle ban.' if event.message.mentions.length != 1
          raise 'You must use this command in a associated #voice-channel.' if vc.nil?
          raise "Only the owner of this channel (#{student_owner.mention}) and moderators can ban users!" unless vc.student_owner == user || user.moderator?

          is_banned = Regit::VoiceChannels::toggle_ban_from_voice(vc, event.message.mentions.first.on(event.server), user)

          event.channel.send_message("**#{user.mention} #{is_banned ? 'banned' : 'unbanned'} #{event.message.mentions.first.mention} from the voice-channel.**")
        rescue => e
          user.pm("Failed to ban user from voice-channel: #{e}")
        end

        nil
      end
      
			# Allow voice-channel owners to kick people from the channel
			command(:vkick, description: 'Kick unwanted users from a owned voice-channel.', permission_level: 1, usage: '`!vkick @user1 @user2`') do |event|
				event.message.delete unless event.channel.private?
				
        user = event.user.on(event.server)
        vc = event.channel.associated_channel

        begin
          raise 'You must use this command in a associated #voice-channel.' if vc.nil?
          raise "Only the owner of this channel (#{student_owner.mention}) and moderators can kick users!" unless vc.student_owner == user || user.moderator?

          kicked = Regit::VoiceChannels::kick_from_voice(vc, event.message.mentions, user)
          raise 'Nobody valid was passed.' if kicked.empty?

          event.channel.send_message("**#{user.mention} kicked #{kicked.map { |m| m.mention }.join(', ')} from the voice-channel.**")
        rescue => e
          user.pm("Failed to kick users from voice-channel: #{e}")
        end

        nil
      end
			
      command(:rename, description: 'Change name of a voice room.', permission_level: 1, min_args: 0, max_args: 1) do |event, new_name|
        event.message.delete unless event.channel.private?

        # Check if in #voice-channel
        unless event.channel.association == :voice_channel
          event.channel.send_temporary_message("You must use this in #{event.user.voice_channel.associated_channel.mention}!", 5) unless event.user.voice_channel.nil?
          return
        end

        voice_channel = event.channel.associated_channel
        return nil if voice_channel.nil?

        # Make sure is a disposable voice room
        unless voice_channel.name.start_with? 'Room '
          event.channel.send_temporary_message('You cannot rename this voice-channel!', 5)
          return
        end

        # Validate new_name
        # max_length = 100
        new_name.strip!
        
        max_length = 100 - 'Room '.length # 95; easy to change later on
        new_name = new_name[0..max_length-1]

        voice_channel.name = "Room #{new_name}"
        event.channel.topic = "Private chat for all those in the voice-channel **#{voice_channel.name}** | Owned by #{voice_channel.student_owner.mention}"

        "**#{event.user.display_name}** renamed room to **Room #{new_name}**."
      end
    end
  end
end