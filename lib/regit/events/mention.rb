module Regit
  module Events
    module Mention
      extend Discordrb::EventContainer

      mention do |event|
        #event.respond event.server.school.title + event.user.on(event.server).info.first_name
      end
    end
  end
end