# Example command module

module Regit
  module Commands
    module Quotes
      extend Discordrb::Commands::CommandContainer

      command(:addquote, description: 'Quote something you or a friend said!', usage: '`!addquote "something thing"` or `!addquote` or `!addquote "something something @user` or `!addquote @user`', min_args: 0, max_args: 2, permission_level: 1) do |event, message|
        event.message.delete unless event.channel.private?

        ms = event.message.mentions
        # Determine method
        # 1 - message, no mention
        # 2 - message, mention
        # 3 - no message, mention
        # 4 - no message, no mention
        method = nil
        author = event.user

        message = nil unless Regit::BOT.parse_mention(message).nil?

        if message.nil? && ms.empty?
          method = 4
          begin
            found_message = event.channel.history(30).find { |m| !m.content.start_with?('!') && !m.author.info.nil? }
          rescue => e
            LOGGER.error e
            event.channel.send_temporary_message('Failed to find a recent message.', 5)
            return
          end

          author = found_message.author
          message = found_message.content
        elsif message.nil? && !ms.empty?
          method = 3
          # Find message

          begin
            message = event.channel.history(30).find { |m| m.author == ms.first && !m.content.start_with?('!') && !m.author.info.nil? }.content
          rescue => e
            LOGGER.error e
            event.channel.send_temporary_message("Failed to find a recent message by **#{ms.first}**", 5)
            return
          end
          author = ms.last
        elsif !message.nil? && ms.empty?
          method = 1
        elsif !message.nil? && !ms.empty?
          method = 2
          author = ms.last
        end

        author = author.on(event.server)

        Regit::Quotes::add_quote(event.user.on(event.server), author, message)
        "Saved quote `#{message}` by #{author.short_info}"
      end
    end
  end
end