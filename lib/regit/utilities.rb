module Regit
  module Utilities

    def self.announce(server, message)
      announcement_channel = server.text_channels.find { |t| t.name == 'announcements' }

      unless announcement_channel.nil? || message.nil? || message.empty?
        announcement_channel.send_message "@everyone #{message}"
      end
    end

    def self.list_to_perms(perms)
      allow = Discordrb::Permissions.new
      deny = Discordrb::Permissions.new
      
      perms.each do |p|
        if p.start_with? '-'
          # Deny
          begin
            deny.send("can_#{p.gsub('-', '')}=", true)
          rescue NoMethodError => e
            LOGGER.info "Discordrb can't handle #{p} yet. Skipping."
          end
        else
          # Allow
          begin
            allow.send("can_#{p}=", true)
          rescue NoMethodError => e
            LOGGER.info "Discordrb can't handle #{p} yet. Skipping."
          end
        end
      end

      { allow: allow, deny: deny }
    end

    # Remove any remnants 
    def self.clean_channels(server)
      server.text_channels.select { |t| t.association.nil? }.map(&:delete)
      server.roles.select { |r| r.association.nil? }.map(&:delete)
    end

    def self.replace_mentions(message)
      message.strip!
      message.gsub! '**', ''
      message.gsub! '@everyone', '**everyone**'
      message.gsub! '@here', '**here**'
      words = message.split ' '

      words.each_with_index do |w, i|
        w.sub!('(', '')
        w.sub!(')', '')
        w.gsub!('"', '')
        w.gsub!('*', '')

        unless Regit::BOT.parse_mention(w).nil?
          # See if mention is student
          user = Regit::BOT.parse_mention(w)

          student = Regit::Database::Student.find_by_discord_id(user.id)
          message.gsub!(w, (student.nil? ? user.distinct : student.description)) unless user.nil?
        end
      end

      return message.sub('@', '') if words.length == 1 and done == 1
      return message
    end

  end
end
