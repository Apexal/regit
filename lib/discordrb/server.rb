module Discordrb
  
  class Server
    attr_reader :school

    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, exists = true|
      old_initialize.bind(self).call(data, bot, exists)

      @school = Regit::Database::School.find_by_server_id(@id)
      if @school.nil?
        LOGGER.info 'Adding school to Database'
        @school = Regit::Database::School.create(title: 'School', school_type: 'High School', server_id: @id)
      end
      LOGGER.debug @school.title
    end
  end
end
