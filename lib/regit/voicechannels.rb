module Regit
  module VoiceChannels

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