# Example command module

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

      command(:report, description: 'Report a user for breaking the rules.', usage: '`!report @who "reason"` or `!report "reason" @who`', permission_level: 1) do |event, *reason|
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