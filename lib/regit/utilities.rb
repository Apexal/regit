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

        if w.start_with? '<@' and w.end_with? '>' && !done.include?(id)
          id = w.sub('<@!', '').sub('<@', '').sub('>', '')

          user = Regit::BOT.parse_mention(w)
          message.gsub(user.mention, user.distinct) unless user.nil?
          
          done << id
        end
      end

      return message.sub('@', '') if words.length == 1 and done == 1
      return message
    end

  end
end
