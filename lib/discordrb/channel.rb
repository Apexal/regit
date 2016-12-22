module Discordrb
  class Channel
    attr_reader :association

    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, server = nil|
      old_initialize.bind(self).call(data, bot, server)

      if data['type'] == 2    
        @association = :group if data['name'].start_with? 'Group '
        @association = :grade if Regit::GRADES.include?(data['name'])
      end

    end

  end
end