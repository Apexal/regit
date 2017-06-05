# Example command module

module Regit
  module Commands
    module VoiceCommands
      extend Discordrb::Commands::CommandContainer
			
      # Allows guests to enter a voice room
      command(:allowguests, description: 'Allow guests to enter a voice room.', permission_level: 1, usage: '`!allowguests` in a #voice-channel') do |event|
        event.message.delete unless event.channel.private?

        user = event.user.on(event.server)
        vc = event.channel.associated_channel

        begin
          raise 'You must use this command in a associated #voice-channel.' if vc.nil?
          raise "Only the owner of this channel (#{student_owner.mention}) and moderators can allow guests!" unless vc.student_owner == user || user.moderator?

          Regit::VoiceChannels::set_room_guests(vc, true)
          event.channel.send_message("#{user.short_info} has allowed **Guests** to enter this voice channel.")
        rescue => e
          event.user.pm("Failed to allow guests: #{e}")
        end

        nil
      end

      # Prevent Guests from entering a voice room
      command(:denyguests, description: 'Deny guests from entering a voice room.', permission_level: 1, usage: '`!denyguests` in a #voice-channel') do |event|
        event.message.delete unless event.channel.private?

        user = event.user.on(event.server)
        vc = event.channel.associated_channel

        begin
          raise 'You must use this command in a associated #voice-channel.' if vc.nil?
          raise "Only the owner of this channel (#{student_owner.mention}) and moderators can deny guests!" unless vc.student_owner == user || user.moderator?

          Regit::VoiceChannels::set_room_guests(vc, false)
          event.channel.send_message("#{user.short_info} has denied **Guests** from entering this voice channel.")
        rescue => e
          event.user.pm("Failed to deny guests: #{e}")
        end

        nil
      end

      # Allow voice-channel owners to ban people from the channel
      command(:vban, description: 'Toggle ban of unwanted user from a voice-channel.', permission_level: 1, usage: '`!vban @user`') do |event|
        event.message.delete unless event.channel.private?
				
        user = event.user.on(event.server)
        vc = event.channel.associated_channel

        begin
          raise 'You must give 1 user to toggle ban.' if event.message.mentions.length != 1
          raise 'You must use this command in a associated #voice-channel.' if vc.nil?
          raise "Only the owner of this channel (#{student_owner.mention}) and moderators can ban users!" unless vc.student_owner == user || user.moderator?

          is_banned = Regit::VoiceChannels::toggle_ban_from_voice(vc, event.message.mentions.first.on(event.server), user)

          event.channel.send_message("#{user.short_info} #{is_banned ? 'banned' : 'unbanned'} #{event.message.mentions.first.mention} from the voice-channel.**")
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
          raise "Only the owner of this channel (#{vc.student_owner.mention}) and moderators can kick users!" unless vc.student_owner == user || user.moderator?

          kicked = Regit::VoiceChannels::kick_from_voice(vc, event.message.mentions, user)
          raise 'Nobody valid was passed.' if kicked.empty?

          event.channel.send_message("**#{user.display_name} *(#{user.info.short_description})* kicked #{kicked.map { |m| m.mention }.join(', ')} from the voice-channel.**")
        rescue => e
          user.pm("Failed to kick users from voice-channel: #{e}")
        end

        nil
      end
			
      command(:rename, description: 'Change name of a voice room.', permission_level: 1, min_args: 1, max_args: 1) do |event, new_name|
        event.message.delete unless event.channel.private?
        
        user = event.user.on(event.server)
        voice_channel = event.channel.associated_channel

        begin
          raise 'You must use this command in a associated #voice-channel.' if voice_channel.nil?
          raise "Only the owner of this channel (#{voice_channel.student_owner.mention}) and moderators can kick users!" unless voice_channel.student_owner == user || user.moderator?

          new_name = Regit::VoiceChannels::rename_room(voice_channel, new_name)
          event.channel.send_message("**#{user.display_name} *(#{user.info.short_description})*** renamed room to **#{voice_channel.name}**.")
        rescue => e
          event.user.pm "Failed to rename room: #{e}"
        end

        nil
      end
    end
  end
end