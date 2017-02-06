module Discordrb
  class Server
    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, exists = true|
      old_initialize.bind(self).call(data, bot, exists)
    end

    def school
      Regit::Database::School.find_by_server_id(@id)
    end

    def students
      members.select { |m| m.student?(school) }
    end

    def setup?
      !school.nil?
    end
  end
end
