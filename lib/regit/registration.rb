require 'securerandom'

module Regit
  module Registration
    extend StoreData

    VERIFY_CODES = load_file("#{Dir.pwd}/data/verify_codes.yaml")
    # { 
    #   student_username: random_code, 
    #   student_username: random_code
    # }

    # When user enters username
    def self.start_process(member, username)
      raise 'Invalid username format!' unless /^[a-z]+\d{2}$/.match(username)
      raise 'Already registered.' unless member.info.nil?

      LOGGER.info "Starting registration process for #{username}"
      
      # Gen random code for user
      code = SecureRandom.hex
      VERIFY_CODES[username] = code

      code # Return to send in email
    end

    def self.verify_student(member, code)
      username = VERIFY_CODES.key(code)
      raise 'Invalid code!' if username.nil?

      # Link student to Discord account
      Regit::Database::Student.find_by_username(username).update(discord_id: member.id)
      LOGGER.info "Linked #{member.distinct} to #{username}"
    end

    def self.setup_channels(member)

    end

    def self.handle_course_channel(course)
      # Create text-channel
      # Save in DB
      # Return text-channel
    end

    # After verifying, setup a student
    def self.setup_user(member)
      server = member.server
      LOGGER.info "Setting up #{member.distinct} | #{member.info.description}"

      # Add student role
      member.add_role(server.roles.find { |r| r.name == 'Students' })

      # Add grade role
      member.add_role(server.roles.find { |r| r.name == member.info.grade_name })

      # Default groups
      Regit::Database::Group.where(default_group: true).each do |g|
        Regit::Groups::add_to_group(member, g.id)
      end

      setup_channels(member)
      VERIFY_CODES.delete(member.info.username)
    end
  end
end