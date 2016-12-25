module Discordrb
  class Role
    default_roles = load_file("#{Dir.pwd}/data/default_roles.yaml")

    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, server = nil|
      old_initialize.bind(self).call(data, bot, server)
    end

    def association
      if Regit::Database::Group.find_by_role_id(id).count > 0
        :group
      end
    end

    def description
      begin
        default_roles[name].description
      rescue;end
    end
  end
end