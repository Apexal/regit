module Discordrb
  class Role
    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, server = nil|
      old_initialize.bind(self).call(data, bot, server)
    end

    def association
      colors = %w(blue orange purple green yellow pink red)
      small_advs = Regit::Database::Student.distinct.pluck(:advisement)
      large_advs = small_advs.map { |a| a[0..1] }.uniq

      if !Regit::Database::Group.find_by_role_id(@id).nil?
        :group
      elsif @name == 'Consul'
        :consul
      elsif Regit::GRADES.include?(@name)
        :grade
      elsif !Regit::DEFAULT_ROLES[@name].nil?
        :default
      elsif small_advs.include?(@name) || large_advs.include?(@name)
        :advisement
      elsif @name.start_with?('#')
        :color
      elsif @name == 'bots'
        :bots
      elsif @server.id == @id
        :everyone
      elsif @name == 'Regit'
        :self
      end
    end

    def description
      begin
        Regit::DEFAULT_ROLES[@name]['description']
      rescue;end
    end
  end
end