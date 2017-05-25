module Regit
  module VoiceChannels

    # These are the perms given to people for a associated voice-channel
    TEXT_PERMS = Discordrb::Permissions.new
    TEXT_PERMS.can_read_message_history = true
    TEXT_PERMS.can_read_messages = true
    TEXT_PERMS.can_send_messages = true

    def self.save_associations
      save_to_file("#{Dir.pwd}/data/associations.yaml", CHANNEL_ASSOCIATIONS)
    end

    def self.trim_voice_associations(server)
      server.associations.each do |vc_id, tc_id|
        server.associations.delete(vc_id) if tc_id.nil? || server.voice_channels.find { |vc| vc.id == vc_id }.nil?
      end
      save_associations
    end

    def self.setup_server_voice(server)
      LOGGER.info "Setting up voice system for [#{server.name}]"
      LOGGER.info 'Trimming associations'
      trim_voice_associations(server)

      LOGGER.info 'Cleaning up after restart...'

      # Loop through existing #voice-channel text channels and make sure they are associated or delete them
      server.text_channels.select { |tc| tc.association == :voice_channel }.each do |tc|
        unless server.associations.values.include?(tc.id)
          # Not associated
          tc.delete
          next
        end

        vc = server.voice_channels.find { |vc| vc.id == server.associations.key(tc) } # Associated voice-channel
        tc.users.select { |u| !vc.users.include?(u) }.each do |u|
          # Users not in the voice channel but somehow in the #voice-channel text channel
          tc.define_overwrite(u, 0, 0) # Effectively removes their perms to see the #voice-channel
        end
      end

      LOGGER.info 'Associating...'
      server.voice_channels.each { |vc| associate(vc) }
      OLD_VOICE_STATES[server.id] = server.voice_states.clone
      LOGGER.info 'Done'
    end

    def self.associate_voice_channel(voice_channel)
      server = voice_channel.server
      return if voice_channel == server.afk_channel # No need for AFK channel to have associated text-channel

      puts "Associating '#{voice_channel.name} / #{server.name}'"
      text_channel = server.text_channels.find { |tc| tc.id == server.associations[voice_channel.id] }

      if server.associations[voice_channel.id].nil? || text_channel.nil?
        text_channel = server.create_channel('voice-channel', 0) # Creates a matching text-channel called 'voice-channel'
        text_channel.topic = "Private chat for all those in the voice-channel [**#{voice_channel.name}**]."
        
        # Give each voice channel member perms to see the new associated text-channel
        voice_channel.users.each do |u|
          text_channel.define_overwrite(u, TEXT_PERMS, 0)
        end

        text_channel.define_overwrite(voice_channel.server.roles.find { |r| r.id == voice_channel.server.id }, 0, TEXT_PERMS) # Set default perms as invisible
        server.associations[voice_channel.id] = text_channel.id # Associate the two 
        save_associations
      end

      text_channel
    end

    def self.toggle_ban_from_voice(channel, target, user=nil)
      raise 'This channel doesn\'t have an owner...' if channel.student_owner.nil?
      
      # Check for mention(s)
      raise 'You must say what users you want to toggle ban! `!vban @user1`' if target.nil?
      
      perms = Discordrb::Permissions.new
      perms.can_connect = true

      # Kick target (set override)
      if target.permission?(:connect, channel)
        # Ban
        channel.define_overwrite(target, 0, perms)
        target.pm("You've been banned from **#{channel.name} / #{channel.server.name}**")
        kick_from_voice(channel, [target], user)
        LOGGER.info "Banned #{target.distinct} from #{channel.name} / #{channel.server.name}"
        return true
      else
        # Unban
        channel.define_overwrite(target, 0, 0)
        target.pm("You've been unbanned from **#{channel.name} / #{channel.server.name}**")
        
        LOGGER.info "Unbanned #{target.distinct} from #{channel.name} / #{channel.server.name}"
        return false
      end
    end

    def self.kick_from_voice(channel, targets, user=nil)
      raise 'This channel doesn\'t have an owner...' if channel.student_owner.nil?
      
      # Check for mention(s)
      raise 'You must say what users you want to kick! `!vkick @user1 @user2`' if targets.empty?
      
      # Kick every target (move to AFK channel)
      kicked = []
      targets.each do |target|
        next if target == user || target.on(channel.server).voice_channel != channel
        kicked << target
        channel.server.move(target, channel.server.afk_channel)
      end
      
      kicked
    end

  end
end