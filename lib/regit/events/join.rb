module Regit
  module Events
    module Join
      extend Discordrb::EventContainer

      member_join do |event|
        # A possible student has just joined a school server
        event.server.owner.pm("#{event.user.mention} has just joined the server! Sending quickstart info.")
        
        event.user.pm.start_typing
        sleep 5
        event.user.pm.send_temporary_message("Welcome to the Discord server for **#{event.server.school.title} #{event.server.school.school_type}**!", 5, true)
      end
    end
  end
end