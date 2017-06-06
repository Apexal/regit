# Example command module

module Regit
  module Commands
    module Studymode
      extend Discordrb::Commands::CommandContainer

      # Show or hide non-work related text-channels and voice-channels
      def self.set_study_mode(member, is_on)
        server = member.server

        studyrole = server.roles.find { |r| r.name == 'Studying' }

        perms = Discordrb::Permissions.new
        perms.can_read_messages = true
        perms.can_read_message_history = true
        perms.can_send_messages = true

        # Channels to apply overrides to
        text_channels = [server.text_channels.find { |t| t.name == 'public-room' }, server.text_channels.find { |t| t.name == member.info.grade_name.downcase }] + member.info.groups.map { |g| g.text_channel }
        text_channels.each do |t|
          t.define_overwrite(member, 0, perms) if is_on
          t.define_overwrite(member, 0, 0) unless is_on
        end

        # Fix for grade voice_channels
        v_perms = Discordrb::Permissions.new
        v_perms.can_connect = true
        grade_channel = server.voice_channels.find { |v| v.name == member.info.grade_name }
        grade_channel.define_overwrite(member, 0, v_perms) if is_on
        grade_channel.define_overwrite(member, 0, 0) unless is_on

        member.add_role(studyrole) if is_on
        member.remove_role(studyrole) unless is_on
        
        # Voice-channels
        if !member.voice_channel.nil? and !member.permission?('can_connect', member.voice_channel)
          LOGGER.info "Moving #{member.distinct} to allowed voice-channel"
          server.move(member, server.voice_channels.find { |c| c.name == Regit::CONFIG.new_room_name })
          member.pm 'You were moved into a new voice-channel because your previous one only allowed students in studymode.'
        end

        member.nickname = '[S] ' + member.display_name if is_on
        member.nickname = member.display_name.sub('[S] ', '') unless is_on
        #LOGGER.info text_channels
      end

      command(:study, description: 'Show description.', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event|
        event.message.delete unless event.channel.private?

        begin
          set_study_mode(event.user, !event.user.studying?)
          event.user.pm "**Studymode** is now *#{event.user.studying? ? 'on' : 'off'}*."  
        rescue => e
          LOGGER.error "Failed to toggle studymode: #{e}"
          LOGGER.error e.backtrace.join("\n")
          event.user.pm "Failed to toggle studymode: #{e}"
        end
      end
    end
  end
end