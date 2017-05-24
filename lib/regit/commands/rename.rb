# Example command module

module Regit
  module Commands
    module Rename
      extend Discordrb::Commands::CommandContainer
			
			# Allow voice-channel owners to kick people from the channel
			command(:vkick, description: 'Kick unwanted users from a owned voice-channel.', permission_level: 1, usage: '`!vkick @user1 @user2`') do |event|
				event.message.delete unless event.channel.private?
				
				vc = event.channel.associated_channel
				return event.channel.send_temporary_message('You must use this in a #voice-channel', 5) if vc.nil?

				return event.channel.send_temporary_message("This channel doesn't have an owner...", 5) if vc.student_owner.nil?
				return event.channel.send_temporary_message("Only the owner of this channel (#{student_owner.mention}) can kick users!", 5) unless vc.student_owner == event.user
				
				# Check for mention(s)
				return event.channel.send_temporary_message("You must say what users you want to kick! `!vkick @user1 @user2`", 7) if event.message.mentions.empty?
				
				# Kick every target (move to AFK channel)
				event.message.mentions.each do |target|
					next if target.on(event.server).info.nil? || target == event.user
    
					event.server.move(target, event.server.afk_channel)
				end
				
				return event.channel.send_message("**Channel owner #{vc.student_owner.mention} kicked #{event.message.mentions.map { |m| m.mention }.join(', ')} from the voice-channel.")
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
        event.channel.topic = "Private chat for all those in the voice-channel **#{voice_channel.name}**."

        "**#{event.user.display_name}** renamed room to **Room #{new_name}**."
      end
    end
  end
end