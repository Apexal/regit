module Regit
  module Commands
    module Moderation
      extend Discordrb::Commands::CommandContainer

      def self.send_report(channel, from, about, reason)
        mod_channel = channel.server.text_channels.find { |t| t.name == 'moderators' }
        
        raise 'Missing channel' if channel.nil?
        raise 'Missing from' if from.nil?
        raise 'Missing about' if about.nil?
        raise 'Missing reason' if reason.nil? || reason.empty?

        LOGGER.info reason
        reason = reason.split(' ').select { |word| Regit::BOT.parse_mention(word).nil? }.join(' ').strip # In case mention is first

        # TODO: save reports in DB maybe
        mod_channel.send_message("#{channel.server.roles.find { |r| r.name == 'Moderators' }.mention} **Report from #{from.mention} concerning #{about.mention} in #{channel.mention}:** #{reason}") unless mod_channel.nil?
        LOGGER.info "Report from #{from.mention} concerning #{about.mention} in #{channel.mention} (#{channel.server.name}):** #{reason} "
      end

      def self.set_mute(member, text_channel, is_muted)
        # Check target
        raise 'Only students and guests can be muted!' if member.info.nil?
        raise 'You can not mute fellow Moderators!' if member.roles.find { |r| r.name == 'Moderators' }

        if is_muted
          # Perms for non-group members
          muted_perms = Discordrb::Permissions.new
          muted_perms.can_send_messages = true

          text_channel.define_overwrite(member, 0, muted_perms)
        else
          text_channel.define_overwrite(member, 0, 0)
        end

        #member.add_role(member.server.roles.find { |r| r.name == 'Muted' }) if is_muted # Better work
        #member.remove_role(member.server.roles.find { |r| r.name == 'Muted' }) unless is_muted # Better work
        
        is_muted
      end

      command(:mute, description: 'Toggle text mute a user for breaking the rules.', usage: '`!mute @target`', permission_level: 2) do |event|
        event.message.delete unless event.channel.private?
        target = (event.message.mentions.empty? ? nil : event.message.mentions.first.on(event.server))

        begin
          raise 'Command must be used on school server.' if event.channel.private?
          raise 'You can\'t mute yourself!' if event.user == target

          set_mute(target, event.channel, !target.muted?(event.channel))

          target.pm "You have been **#{target.muted?(event.channel) ? 'muted' : 'unmuted'}** in #{event.channel.mention} by a Moderator on *#{event.server.name}*!"
          event.user.pm "Target has been **#{target.muted?(event.channel) ? 'muted' : 'unmuted'}** in #{event.channel.mention}."
        rescue => e
          event.user.pm "Failed to mute target: #{e}"
          LOGGER.error e.backtrace
        end

        nil
      end

      command(:report, description: 'Report a user for breaking the rules.', usage: '`!report @who "reason"` or `!report "reason" @who`', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event, *reason|
        event.message.delete unless event.channel.private?

        target = (event.message.mentions.empty? ? nil : event.message.mentions.first.on(event.server))
        
        begin
          send_report(event.channel, event.user, target, reason.join(' '))
          event.user.pm 'Sent report!'
        rescue => e
          LOGGER.error e
          event.user.pm "Failed to send report: #{e}"
        end

        nil
      end
    end
  end
end