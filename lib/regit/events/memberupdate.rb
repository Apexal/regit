module Regit
  module Events
    module MemberUpdate
      extend Discordrb::EventContainer

      member_update do |event|
        # Check for nickname conflict
        member = event.user.on(event.server)

        nickname = member.nickname
        
        unless if nickname.nil?
          other = event.server.members.find { |m| !m.nickname.nil? && m.nickname.downcase.delete(' ') == nickname.downcase.delete(' ') && m != member}
          unless other.nil?
            LOGGER.info other.distinct
            # COPIED SOMEBODY'S NICKNAME
            other.pm "#{member.mention} *[#{member.info.description}]* tried to steal your nickname. It has been prevented."
            member.nickname = nil
            member.pm "You have been prevented from stealing #{other.mention} *[#{other.info.description}]*'s nickname."

            LOGGER.info "#{member.display_name} *[#{member.info.description}]* tried to copy #{other.display_name} *[#{other.info.description}]*'s nickname and was prevented."
          end
        end
        
      end
    end
  end
end