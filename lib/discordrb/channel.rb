module Discordrb
  class Channel
    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, server = nil|
      old_initialize.bind(self).call(data, bot, server)
    end
	
		def student_owner
			Regit::CHANNEL_OWNERS[@server.id][@id].nil? ? nil : @server.members.find { |m| m.id == Regit::CHANNEL_OWNERS[@server.id][@id] }
		end
		
    def association
      small_advs = Regit::Database::Student.distinct.pluck(:advisement)
      large_advs = small_advs.map { |a| a[0..1] }.uniq

      if @type == 0
        if @name == 'voice-channel'
          :voice_channel
        elsif @name == 'finals'
          :finals
        elsif !Regit::Database::Group.find_by_text_channel_id(@id).nil?
          :group
        elsif @name == 'groups'
          :groups
        elsif Regit::GRADES.map { |g| g.downcase }.include?(@name)
          :grade
        elsif !Regit::DEFAULT_TEXT_CHANNELS[@name].nil?
          :default
        elsif small_advs.include?(@name.upcase) || large_advs.include?(@name.upcase)
          :advisement
        elsif Regit::Database::Course.where(school_id: @server.school.id, text_channel_id: @id).count > 0
          :course
        end
      elsif type == 2
        if @name.start_with?('Room ') || @name.start_with?('Study Room ') || @name.end_with?(' Study Room') || @name.end_with?(' Party') || @name.start_with?('Advisement ')
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

    def associated_channel
      return unless [:default, :grade, :room, :voice_channel].include?(association)

      if @type == 2
        Regit::BOT.channel(Regit::CHANNEL_ASSOCIATIONS[@server.id][@id], @server)
      elsif @type == 0
        Regit::BOT.channel(Regit::CHANNEL_ASSOCIATIONS[@server.id].key(@id), @server) rescue nil
      end

    end

  end
end