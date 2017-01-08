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

      message(containing: '@everyone') do |event|
        return if event.channel.private?

        event.channel.send_temporary_message('You can\'t use `@everyone` in this channel. Try using `@here`.`' , 10) unless event.user.on(event.server).permission?(:mention_everyone, event.channel)
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


      message do |event|
        event.message.delete if !event.channel.private? && event.user.on(event.server).role?(event.server.roles.find { |r| r.name == 'Muted' })
      end
    end
  end
end