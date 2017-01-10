module Regit
  module Commands
    module WhoIs
      extend Discordrb::Commands::CommandContainer

      command(:whois, description: 'Show description.', permission_level: 1) do |event|
        if event.channel.private?
          event.user.pm 'You can only use `!whois` on a school server!'
          return
        end

        target = (event.message.mentions.empty? ? event.author : event.message.mentions.first.on(event.server))

        event.channel.send_embed do |embed|
          if target.student?(event.server.school)
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: target.info.pictureurl)
            embed.title = '[Student] ' + target.info.first_name + ' ' + target.info.last_name
            embed.add_field(name: 'School', value: target.info.school.title + ' ' + target.info.school.school_type, inline: true)
            embed.add_field(name: 'Advisement', value: target.info.advisement, inline: true)
            embed.add_field(name: 'Discord Tag', value: "#{target.mention} | #{target.distinct}", inline: true)
            embed.add_field(name: 'Birthday', value: target.info.birthday.strftime('%B %e, %Y '), inline: true)
            
            embed.color = 7380991
            embed.color = 16720128 if target.role?(target.server.roles.find { |r| r.name == 'Moderators' })
            
            embed.url = 'https://example.com' # TODO: change
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Joined at #{target.joined_at}", icon_url: target.avatar_url)
          elsif target.guest?(event.server.school)
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
      end
    end
  end
end