module Discordrb
  class Member
    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, server, bot|
      old_initialize.bind(self).call(data, server, bot)
    end

    def info
      Regit::Database::Student.find_by_discord_id(@user.id)
    end

    def student?(school)
      !info.nil? && info.school_id == school.id
    end

    def guest?(school)
      !info.nil? && info.school_id != school.id
    end
  end
end