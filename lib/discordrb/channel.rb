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
        elsif !Regit::DEFAULT_TEXT_CHANNELS[@name].nil?
          :default
        end
      elsif type == 2
        #LOGGER.info((@server.afk_channel.nil? ? '' : @server.afk_channel.name))
        if @name.start_with?('Room ')
          :room
        elsif @name.start_with?('Group ')
          :group
        elsif @name == Regit::CONFIG.new_room_name
          :new_room
        elsif Regit::GRADES.include?(@name)
          :grade
        elsif !Regit::DEFAULT_VOICE_CHANNELS[@name].nil?
          :default
        elsif (!@server.afk_channel.nil? && @server.afk_channel.id == @id) || @name == 'AFK'
          :afk
        end
      else
        :dm
      end
    end

  end
end