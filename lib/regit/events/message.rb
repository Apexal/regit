module Regit
  module Events
    module Mention
      extend Discordrb::EventContainer

      message(containing: '@') do |event|
        mentions = []

        usernames = []

        words = event.message.content.split ' '
        words.each do |w|
          next if usernames.include? w
          usernames << w
          if w.start_with? '@'
            username = w.tr('@', '')
            next unless username.match(/^\w+[1-9]{2}$/)

            student = Regit::Database::Student.find_by_username(username)
            mentions.append(student.member) unless student.nil?
          end
        end

        event.channel.send("^^^ #{mentions.map { |m| m.mention }.join(' ')}") unless mentions.empty?
      end

      message(containing: '@here') do |event|
        return if event.channel.private?
        # Check if channel allows @everyone
        
        unless event.user.on(event.server).permission?(:mention_everyone, event.channel)
          m = event.channel.send_message '^^^ @here'
          LOGGER.info "Manually replace @here in ##{event.channel.name}"
          sleep 1
          m.delete
        end
      end

    end
  end
end