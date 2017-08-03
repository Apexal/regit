module Regit
  module Events
    module Mention
      extend Discordrb::EventContainer

      # Allow mentioning of students by Regis username
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

        # Warn about use of @everyone when user doesn't have permission to use it
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
        begin
          event.message.delete if !event.channel.private? && event.user.on(event.server).role?(event.server.roles.find { |r| r.name == 'Muted' })
        rescue
          LOGGER.error 'Could not find author of message.'
        end
      end

      reaction_add(emoji: ["☑", "❌"]) do |event|
        next if event.channel.private?

        next unless event.channel.association == :voice_channel

        vc = event.channel.associated_channel
        vote = VOTEKICKS[vc.server.id][vc.id].find { |v| v[:message] == event.message }
        next if vote.nil?

        choice = event.emoji.to_s == '<:☑:>' ? :yes : :no 
        if choice == :yes
          event.message.delete_reaction(event.user, '❌')
        else
          event.message.delete_reaction(event.user, '☑')
        end

        Regit::VoiceChannels::handle_vote_kick(vote[:target])
      end

      reaction_remove(emoji: ["☑", "❌"]) do |event|
        next if event.channel.private?

        next unless event.channel.association == :voice_channel

        vc = event.channel.associated_channel
        vote = VOTEKICKS[vc.server.id][vc.id].find { |v| v[:message] == event.message }

        next if vote.nil?

        Regit::VoiceChannels::handle_vote_kick(vote[:target])
      end

    end
  end
end