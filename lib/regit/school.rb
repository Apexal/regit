module Regit
  module School

    # Returns whether it is summer vacation
    def self.summer?(school)
      false
    end

    # Deletes all course text-channels on a server
    def self.close_course_channels(server)
      server.text_channels.select { |tc| tc.association == :course }.each do |tc|
        LOGGER.info "Deleting text-channel ##{tc.name} [#{tc.topic}] (#{tc.id})"
        
        begin
          tc.delete
        rescue => e
          LOGGER.error "Somehow failed to delete channel: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end
      end
    end

    def self.remove_advisement_channels(server)
      server.text_channels.select { |tc| tc.association == :advisement }.each do |tc|
        LOGGER.info "Deleting text-channel ##{tc.name} [#{tc.topic}] (#{tc.id})"
        
        begin
          puts "DELETED: ##{tc.name}"
          tc.delete
        rescue => e
          LOGGER.error "Somehow failed to delete channel: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end
      end
    end

    def self.remove_advisement_roles(server)
      server.roles.select { |r| r.association == :advisement }.each do |r|
        r.delete
      end

      'Done'
    end

    # Removes all advisement roles from users but doesnt delete them and assigns `Class of [YEAR]` roles
    def self.remove_advisement_roles_old(server)
      server.students.each do |m|
        LOGGER.info "Removing advisement roles for #{m.short_info}"

        begin
          adv_roles = m.roles.select { |r| r.association == :advisement }
          LOGGER.info adv_roles.map { |r| r.name }
          m.remove_role(adv_roles)

          # Add class roles
          role_c = server.roles.length
          class_role = server.roles.find { |r| r.name == "Class of #{m.info.graduation_year}" }

          if class_role.nil?
            class_role = server.create_role
            class_role.name = "Class of #{m.info.graduation_year}"
            class_role.hoist = true
            class_role.mentionable = true

            #class_role.position = role_c - 13 # Places it at the top
          end

          LOGGER.info "Adding role #{class_role.name}"
          m.add_role(class_role)
        rescue => e
          LOGGER.error "Somehow failed to remove advisement roles: #{e}"
          LOGGER.error e.backtrace.join("\n")
        end
      end
    end
  end
end