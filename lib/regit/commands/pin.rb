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

        if message.pinned?
          message.unpin
        else
          message.pin
        end

        nil
      end
    end
  end
end