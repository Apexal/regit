
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

      def server
        Regit::BOT.server(server_id)
      end

      def members
        Student.where(school_id: id).map { |s| Regit::BOT::member(server_id, Integer(s.discord_id)) }
      end
    end

    class Student < ActiveRecord::Base
      belongs_to :school, inverse_of: :students
    end

    class Course < ActiveRecord::Base
      belongs_to :school, inverse_of: :courses
    end

    class Group < ActiveRecord::Base
      belongs_to :school, inverse_of: :groups

      def owner
        # Find owner
        Regit::BOT.user(Student.where(username: owner_username).first.discord_id)
      end

      def text_channel
        Regit::BOT.channel(text_channel_id)
      end

      def role
        Regit::BOT.servers.each do |id, server|
          role = server.role(Integer(role_id))
          return role unless role.nil?
        end
        nil
      end

      def private?
        private
      end
    end
  end
end