module Discordrb
  class Member
    attr_reader :info

    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, server, bot|
      old_initialize.bind(self).call(data, server, bot)

      # LINK DATABASE
      @info = Regit::Database::Student.find_by_discord_id(@user.id)
    end
  end
end