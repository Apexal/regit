module Discordrb
  class Channel
    attr_reader :association
    attr_writer :association

    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, server = nil|
      old_initialize.bind(self).call(data, bot, server)

      if data['type'] == 2
        @association = :room if data['name'].start_with? 'Room '
        @association = :group if data['name'].start_with? 'Group '
        @association = :grade if Regit::GRADES.include?(data['name'])
      elsif data['type'] == 0
        @association = :voice_channel if data['name'] == 'voice-channel'
      end

    end

  end
end