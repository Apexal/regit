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
  end
end
