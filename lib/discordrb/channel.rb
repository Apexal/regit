module Discordrb
  class Channel
    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, server = nil|
      old_initialize.bind(self).call(data, bot, server)
    end

    def association
      if @type == 0
        if @name == 'voice-channel'
          :voice_channel
        elsif !Regit::Database::Group.find_by_text_channel_id(@id).nil?
          :group
        elsif Regit::GRADES.map { |g| g.downcase }.include?(@name)
          :grade
        end
      elsif type == 2
        if @name.start_with?('Room ')
          :room
        elsif @name.start_with?('Group ')
          :group
        elsif @name == Regit::CONFIG.new_room_name
          :new_room
        elsif Regit::GRADES.include?(@name)
          :grade
        end
      end
    end

  end
end