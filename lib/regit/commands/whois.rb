module Regit
  module Commands
    module WhoIs
      extend Discordrb::Commands::CommandContainer

      command(:whois, description: 'Show description.') do |event|
        target = (event.message.mentions.empty? ? event.author : event.message.mentions.first.on(event.server))


        event.channel.send_embed do |embed|
          if target.student?(event.server.school)
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: target.info.pictureurl)
            embed.title = '[Student] ' + target.info.first_name + ' ' + target.info.last_name
            embed.add_field(name: 'School', value: target.info.school.title + ' ' + target.info.school.school_type, inline: true)
            embed.add_field(name: 'Advisement', value: '3A-2', inline: true)
            embed.add_field(name: 'Discord Tag', value: "#{target.mention} | #{target.distinct}", inline: true)
            
            embed.color = 7380991
            embed.color = 16720128 if target.role?(target.server.roles.find { |r| r.name == 'Moderators' })
            
            embed.url = 'https://example.com' # TODO: change
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Joined at #{target.joined_at}", icon_url: target.avatar_url)
          elsif target.guest?(event.server.school)
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: target.info.pictureurl)
            embed.title = '[Guest] ' + target.info.first_name + ' ' + target.info.last_name
            embed.add_field(name: 'School', value: target.info.school.title + ' ' + target.info.school.school_type, inline: true)
            embed.add_field(name: 'Discord Tag', value: "#{target.mention} | #{target.distinct}", inline: true)
            embed.color = 16752969
            embed.url = 'https://example.com' # TODO: change
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Joined at #{target.joined_at}", icon_url: target.avatar_url)
          elsif target == event.server.owner
            "That is the owner of the server!"
          else
            "*#{target.display_name}* is not a student."
          end
    
        end
      end
    end
  end
end