module Regit
  module SetUp
    
    def self.set_up_member(member)
      return if member.info.nil?

      member.pm 'Setting you up...'
      LOGGER.info "Setting up #{member.distinct} (#{member.info.email}) on #{member.server.name}."

      # Add students role
      member.add_role(member.server.roles.find { |r| r.name == 'Students' })
      
      # Assign grade role
      grade_role = member.server.roles.find do |r|
        r.name == case member.info.grade
          when 9 then 'Freshmen'
          when 10 then 'Sophomores'
          when 11 then 'Juniors'
          when 12 then 'Seniors'
        end
      end
      member.add_role(grade_role)

      # Add to default groups
      Regit::Database::Group.where(default_group: true).each do |g|
        # Add to group
        LOGGER.info "Added them to group #{g.name}"
        member.add_role(g.role)
      end

      member.pm 'Done! MORE HERE'
    end

  end
end
