module Regit
  module Utilities
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

    def self.replace_mentions(message)
      message.strip!
      message.gsub! '**', ''
      message.gsub! '@everyone', '**everyone**'
      message.gsub! '@here', '**here**'
      words = message.split ' '
      done = []
      words.each_with_index do |w, i|
        w.sub!('(', '')
        w.sub!(')', '')
        w.sub!('"', '')
        if w.start_with? '<@' and w.end_with? '>'
          id = w.sub('<@!', '').sub('<@', '').sub('>', '') # Get ID 
          if !done.include? id and /\A\d+\z/.match(id)
            user = $db.query("SELECT username FROM students WHERE discord_id=#{id}")
            if user.count > 0
              user = user.first
              rep = "**@#{user["username"]}**" # replacement
              message.gsub! "<@#{id}>", rep # Only works when they don't have a nickname
              message.gsub! "<@!#{id}>", rep
            end
            done << id
          end
        end
      end

      return message.sub('@', '') if words.length == 1 and done == 1
      return message
    end

  end
end
