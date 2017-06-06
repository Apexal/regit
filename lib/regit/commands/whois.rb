module Regit
  module Commands
    module WhoIs
      extend Discordrb::Commands::CommandContainer

      command(:whois, description: 'Show description.', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event, username|
        # TARGET IS ONE OF THE FOLLOWING
        # - author of message
        # - first mention
        # - username given

        who = :author
        target = event.author
        
        if !username.nil? && event.message.mentions.empty?
          who = :username
          begin
            target = Regit::Database::Student.find_by_username(username).member
            raise if target.nil?
          rescue
            who = :unregistered unless Regit::Database::Student.find_by_username(username).nil?
            who = :nobody if Regit::Database::Student.find_by_username(username).nil?
          end
        elsif !event.message.mentions.empty?
          who = :mention
          target = event.message.mentions.first.on(event.server)
        end

        event.channel.send_embed do |embed|
          if who == :nobody
            # DOESNT EXIST
            embed.title = 'Invalid User'
            embed.description = 'That user does not exist!'
          elsif who == :unregistered
            # Username of non registered student
            info = Regit::Database::Student.find_by_username(username)
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: info.pictureurl)
            embed.title = '[Student] ' + info.first_name + ' ' + info.last_name
            embed.add_field(name: 'School', value: info.school.title + ' ' + info.school.school_type, inline: true)
            
            if Regit::School::summer?(info.school)
              embed.add_field(name: 'Class of', value: '2018', inline: true)
            else
              embed.add_field(name: 'Advisement', value: info.advisement, inline: true)
            end

            embed.add_field(name: 'Birthday', value: info.birthday.strftime('%B %e, %Y '), inline: true)

            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "#{info.first_name} is not registered on the server yet!")
          elsif [:mention, :author, :username].include?(who) && (who == :username || target.student?(event.server.school))
            target = Regit::Database::Student.find_by_username(username).member if who == :username
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: target.info.pictureurl)
            embed.title = '[Student] ' + target.info.first_name + ' ' + target.info.last_name
            embed.add_field(name: 'School', value: target.info.school.title + ' ' + target.info.school.school_type, inline: true)
            
            if Regit::School::summer?(target.info.school)
              embed.add_field(name: 'Class of', value: '2018', inline: true)
            else
              embed.add_field(name: 'Advisement', value: target.info.advisement, inline: true)
            end
            
            embed.add_field(name: 'Discord Tag', value: "#{target.mention} | #{target.distinct}", inline: true)
            embed.add_field(name: 'Birthday', value: target.info.birthday.strftime('%B %e, %Y '), inline: true)

            embed.color = 7380991
            embed.color = 16720128 if target.role?(target.server.roles.find { |r| r.name == 'Moderators' })

            embed.url = "http://www.getontrac.info:4567/users/#{target.info.username}"
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Joined at #{target.joined_at}", icon_url: target.avatar_url)
          elsif who == :mention && target.guest?(event.server.school)
            embed.title = '[Guest] ' + target.info.first_name + ' ' + target.info.last_name
            embed.add_field(name: 'School', value: target.info.school.title + ' ' + target.info.school.school_type, inline: true)
            embed.add_field(name: 'Discord Tag', value: "#{target.mention} | #{target.distinct}", inline: true)
            embed.color = 16752969
            embed.url = 'https://example.com' # TODO: change
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Joined at #{target.joined_at}", icon_url: target.avatar_url)
          elsif target.bot_account?
            embed.title = 'Regit Bot'
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: 'https://avatars1.githubusercontent.com/u/8422699?v=3&s=460')
            embed.description = "**Regit** is the bot that completely runs and automates all linked school Discord servers."
            embed.url = 'https://github.com/Apexal/regit'
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Created from scratch by Frank Matranga", icon_url: 'http://www.unixstickers.com/image/cache/data/stickers/ruby/ruby.sh-600x600.png')
          else
            embed.title = target.distinct
            embed.description = "#{target.mention} is an unregistered guest. They may or may not be from a school. They are only allowed very limited permissions."
          end
        end

        nil
      end
    end
  end
end