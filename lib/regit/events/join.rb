module Regit
  module Events
    module Join
      extend Discordrb::EventContainer

      member_join do |event|
        # A possible student has just joined a school server
        LOGGER.info "#{} has just joined #{event.server.name} | #{event.server.school.title} #{event.server.school.school_type}"
        event.server.owner.pm("#{event.user.mention} has just joined the server! Sending quickstart info.")
        
        event.user.pm 'Hey there!'
        event.user.pm.start_typing
        sleep 5
        event.user.pm("Welcome to the Discord server for **#{event.server.school.title} #{event.server.school.school_type}**!\n\n*Please enter your school email.*")
        
      end
    end
  end
end