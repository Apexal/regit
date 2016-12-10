module Regit
  module Events
    module Mention
      extend Discordrb::EventContainer

      mention do |event|
        event.respond("I am **Regit**, the successor to <@168184405414772736>")
      end
    end
  end
end