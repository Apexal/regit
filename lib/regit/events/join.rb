module Regit
  module Events
    module Join
      extend Discordrb::EventContainer

      member_join do |event|
        # A possible student has just joined a school server
        LOGGER.info "#{event.user.distinct} has just joined #{event.server.name} | #{event.server.school.title} #{event.server.school.school_type}"
        event.server.owner.pm("#{event.user.mention} has just joined the server! Sending quickstart info.")
        
        event.user.pm 'Hey there!'
        event.user.pm.start_typing
        sleep 5
        event.user.pm(":wave: Welcome to the Discord server for :school: **#{event.server.school.title} #{event.server.school.school_type}**!")
        event.user.pm.start_typing
        sleep 3
        event.user.pm("\n__To get started, log in with your Discord account at http://www.getontrac.info:4567/. And that's it!")
      end
    end
  end
end