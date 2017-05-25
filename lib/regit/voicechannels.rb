module Regit
  module VoiceChannels

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