
module Regit
  module Database
    ActiveRecord::Base.establish_connection(  
      adapter: 'mysql2',  
      host: Regit::CONFIG.db[:host],  
      database: Regit::CONFIG.db[:database],
      username: Regit::CONFIG.db[:username],
      password: Regit::CONFIG.db[:password]
    )

    class School < ActiveRecord::Base
      has_many :students, inverse_of: :school
      has_many :courses, inverse_of: :school
      has_many :groups, inverse_of: :school
    end

    class Student < ActiveRecord::Base
      belongs_to :school, inverse_of: :students
    end

    class Course < ActiveRecord::Base
      belongs_to :school, inverse_of: :courses
    end

    class Group < ActiveRecord::Base
      belongs_to :school, inverse_of: :groups

      def text_channel
        Regit::BOT.channel(text_channel_id)
      end

      def role
        Regit::BOT.servers.each do |id, server|
          role = server.roles.find { |r| r.id == Integer(role_id) }
          return role unless role.nil?
        end
        nil
      end
    end
  end
end