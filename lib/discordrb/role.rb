module Discordrb
  class Role
    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, server = nil|
      old_initialize.bind(self).call(data, bot, server)
      LOGGER.info "#{@name} | #{association}"
    end

    def association
      if !Regit::Database::Group.find_by_role_id(@id).nil?
        :group
      elsif Regit::GRADES.include?(@name)
        :grade
      elsif !Regit::DEFAULT_ROLES[@name].nil?
        :default
      elsif @server.id == @id
        :everyone
      elsif @name == 'Regit'
        :self
      end
    end

    def description
      begin
        Regit::DEFAULT_ROLES[@name].description
      rescue;end
    end
  end
end