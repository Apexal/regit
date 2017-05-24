# Example command module

module Regit
  module Commands
    module Pin
      extend Discordrb::Commands::CommandContainer

      command(:pin, description: 'Toggle pin on last message in a channel.', permission_level: 1, max_args: 0, usage: '`!pin`') do |event|
        event.message.delete
        return if event.channel.private?

        message = event.channel.history(10).find { |m| !m.content.start_with?('!') && !m.content.empty? }
        return event.channel.send_temporary_message('Failed to find a message!', 10) if message.nil?
        
        # Toggle pinned status
        begin
          if message.pinned?
            message.unpin
          else
            message.pin
          end
          LOGGER.info "Toggled pin status on message in #{event.server.name}##{event.channel.name}"
        rescue
          # If it fails, one possibility is that there are too many pinned messages in the channel
          event.user.pm 'Failed to pin messages! There may be too many pinned messages in that channel.'
        end
        
        nil
      end
    end
  end
end
