
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
        Regit::Database::Student.where(school_id: id).where.not(discord_id: nil).map do |s|
          begin
            Regit::BOT::member(server_id, Integer(s.discord_id))
          rescue
            nil
          end
        end.compact
      end

      def groups
        Group.where(school_id: id)
      end

      def staffs
        Staff.where(school_id: id)
      end
    end

    class Student < ActiveRecord::Base
      belongs_to :school, inverse_of: :students
      has_and_belongs_to_many :courses

      def teachers
        courses.select { |c| c.is_class? }.map { |c| c.teacher }.uniq
      end

      def classes
        courses.select { |c| c.is_class? }
      end

      def extracurriculars
        courses.select { |c| !c.is_class? }
      end

      def grade_name
        case grade
          when 9
            'Freshmen'
          when 10
            'Sophomores'
          when 11
            'Juniors'
          when 12
            'Seniors'
        end
      end

      def short_description
        "#{first_name} #{last_name} #{Regit::School::summer?(School.find(school_id)) ? "'18" : "of #{advisement}"}"
      end

      def description
        "#{first_name} #{last_name} of #{advisement} (#{grade}th grade) of #{school.title}"
      end

      def groups
        server = School.find(school_id).server
        Group.all.select do |g|
          member.role?(server.roles.find { |r| r.id == Integer(g.role_id) })
        end
      end

      def member
        School.find(school_id).server.member(discord_id)
      end
    end

    class Staff < ActiveRecord::Base
      has_and_belongs_to_many :courses
    end

    class Course < ActiveRecord::Base
      belongs_to :school, inverse_of: :courses
      belongs_to :staff, inverse_of: :courses, foreign_key: 'teacher_id'
      has_and_belongs_to_many :students

      def text_channel
        begin
          Regit::BOT.channel(text_channel_id) unless text_channel_id.nil?
        rescue => e
          LOGGER.error "Could not find text-channel for course #{id} #{title}: #{e}"
          return nil
        end
      end

      def teacher
        staff
      end

      def class?
        is_class
      end
    end

    class Quote < ActiveRecord::Base
      def added_by
        Regit::BOT.user(Student.find_by_username(username).discord_id)
      end

      def author
        Regit::BOT.user(Student.find_by_username(author_username).discord_id)
      end
    end

    class Group < ActiveRecord::Base
      belongs_to :school, inverse_of: :groups
      after_save :update_channel

      def owner
        # Find owner
        begin
          return Regit::BOT.user(Student.where(username: owner_username).first.discord_id)
        rescue => e
          #LOGGER.error "Could not find group owner for #{name}: #{e}"
          return nil
        end
      end

      def text_channel
        begin
          return Regit::BOT.channel(text_channel_id)
        rescue => e
          LOGGER.error "Could not find text-channel for #{name}: #{e}"
          return nil
        end
      end

      def role
        school.server.role(Integer(role_id))
      end

      def members
        school.server.students.select do |m| 
          begin
            m.role?(role)
          rescue
            false
          end
        end
      end

      def private?
        private
      end

      private
        def update_channel
          # Group owner perms
          owner_perms = Discordrb::Permissions.new
          owner_perms.can_manage_messages = true
          text_channel.define_overwrite(owner, owner_perms, 0) unless owner.nil?

          # Perms for group members
          group_perms = Discordrb::Permissions.new
          group_perms.can_read_messages = true
          group_perms.can_read_message_history = true
          group_perms.can_send_messages = true
          group_perms.can_mention_everyone = true
          
          # All but owner
          text_channel.users.select { |m| owner.nil? || (m.id != owner.id) && m.permission?(:manage_messages, text_channel) && !m.moderator? && !m.studying? }.each do |m|
            text_channel.define_overwrite(m, 0, 0)
          end

          text_channel.topic = "**#{private? ? 'Private ' : ''}Group #{role.name}** | #{description}" + (owner.nil? ? '' : " | Owned by #{owner.mention} | http://www.getontrac.info:4567/groups/#{id}")
        end
    end
  end
end