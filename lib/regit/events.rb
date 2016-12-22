module Regit
  module Events
    # Require all event modules
    Dir["#{File.dirname(__FILE__)}/events/*.rb"].each { |file| require file }

    @events = [
      Mention,
      Ready,
      Join,
      NewServer,
      Presence
    ]

    def self.include!
      @events.each do |event|
        Regit::BOT.include!(event)
      end
    end
  end
end