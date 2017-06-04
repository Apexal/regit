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

    def moderator?
      !roles.find { |r| r.name == 'Moderators' }.nil?
    end

    def guest?(school)
      !info.nil? && info.school_id != school.id
    end

    def studying?
      !roles.find { |r| r.name == 'Studying' }.nil?
    end

    def muted? channel
      !permission?(:send_messages, channel)
    end

    def avatar_url_fixed
      avatar_url.end_with?('/.jpg') ? '/img/noavatar.png' : avatar_url
    end
  end
end