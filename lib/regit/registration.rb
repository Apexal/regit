require 'securerandom'

module Regit
  module Registration
    extend StoreData

    UNALLOWED = ['Advisement', 'Health', 'Guidance', 'Phys Ed']

    VERIFY_CODES = load_file("#{Dir.pwd}/data/verify_codes.yaml")
    # {
    #   student_username: random_code,
    #   student_username: random_code
    # }

    # When user enters username
    def self.start_process(user, username)
      raise 'Invalid username format!' unless /^[a-z]+\d{2}$/.match(username)
      raise 'Already registered.' unless Regit::Database::Student.find_by_discord_id(user.id).nil?

      LOGGER.info "Starting registration process for #{username}"

      # Gen random code for user
      code = SecureRandom.hex
      VERIFY_CODES[username] = code

      code # Return to send in email
    end

    def self.verify_student(user, code)
      username = VERIFY_CODES.key(code)
      raise 'Invalid code!' if username.nil?

      # Link student to Discord account
      student = Regit::Database::Student.find_by_username(username)
      student.update(discord_id: user.id)
      LOGGER.info "Linked #{user.distinct} to #{username}"
      
      student
    end

    def self.unverify_student(user)
      # Remove discord_id link

      student = Regit::Database::Student.find_by_discord_id(user.id) 
      student.update(discord_id: nil)

      # Give away groups
      Regit::Database::Group.where(owner_username: student.username).update_all(owner_username: 'fmatranga18') # Nasty, I know
    end

    def self.handle_advisement_system(member)
      LOGGER.info "Setting up advisement stuff for #{member.distinct} | #{member.info.description}"
      server = member.server
      student = member.info

      large_adv = student.advisement[0..1]
      small_adv = student.advisement

      # Since seniors are in 1 advisement
      advs = student.grade == 12 ? [large_adv] : [large_adv, small_adv]

      # Remove other advisement roles
      other_roles = server.roles.select { |r| !advs.include?(r.name) && Regit::Database::Student.distinct.pluck(:advisement).include?(r.name) }

      new_roles = []

      perms = Discordrb::Permissions.new
      perms.can_read_messages = true
      perms.can_send_messages = true
      perms.can_read_message_history = true
      perms.can_mention_everyone = true

      advs.each do |a|
        adv_role = server.roles.find { |r| r.name == a }
        if adv_role.nil?
          # Need to create role
          adv_role = server.create_role
          adv_role.name = a
          adv_role.hoist = true if a.length <= 2 # If large advisement only
          adv_role.mentionable = true
        end
        new_roles << adv_role

        adv_channel = server.text_channels.find { |t| t.name == a.downcase }
        if adv_channel.nil?
          adv_channel = server.create_channel(a, 0)
          adv_channel.topic = "Private chat for **Advisement #{a}**."

          pos = server.text_channels.find { |t| t.name == 'seniors' }.position
          adv_channel.position = pos

          adv_channel.define_overwrite(adv_role, perms, 0) # Advisement members
          adv_channel.define_overwrite(server.roles.find { |r| r.id == server.id }, 0, perms) # @everyone
        end
      end

      member.modify_roles(new_roles, other_roles)
    end

    def self.handle_course_channels(member)
      # Course channels
      LOGGER.info "Handling course channels for #{member.distinct} | #{member.info.description}"
      courses = member.info.classes
      courses.each { |c| handle_course_channel(member.server, c, member) }
    end

    def self.course_name(full_name)
      full_name = full_name.split(' (')[0].split(' ').join('-')
      full_name.gsub!(/\W+/, '-')
      %w(IV III II I 9 10 11 12).each { |i| full_name.gsub!("-#{i}", '') }

      full_name
    end

    def self.handle_course_channel(server, course, user=nil)
      return if UNALLOWED.any? { |w| course.title.include?(w) }
      LOGGER.info "Handling course channel for #{course.title}"
      text_channel = course.text_channel

      perms = Discordrb::Permissions.new
      perms.can_read_messages = true
      perms.can_send_messages = true
      perms.can_read_message_history = true
      perms.can_mention_everyone = true

      # Create text-channel if not exist
      if text_channel.nil?
        text_channel = server.create_channel(course_name(course.title), 0)
        text_channel.topic = "Discussion room for **#{course.title}** with **#{course.teacher.last_name}**. | http://moodle.regis.org/course/view.php?id=#{course.id}"
        text_channel.send_message("Course Page: http://moodle.regis.org/course/view.php?id=#{course.id}").pin
        text_channel.define_overwrite(server.roles.find { |r| r.id == server.id }, 0, perms)
        course.update(text_channel_id: text_channel.id)
      end
      text_channel.define_overwrite(user, perms, 0) unless user.nil?

      # Save in DB
      # Return text-channel
      text_channel
    end

    # After verifying, setup a student
    def self.setup_user(member)
      server = member.server
      LOGGER.info "Setting up #{member.distinct} | #{member.info.description}"

      new_roles = []

      # Add student role
      new_roles << server.roles.find { |r| r.name == 'Students' }

      # Add grade role
      new_roles << server.roles.find { |r| r.name == member.info.grade_name }

      # Default groups
      Regit::Database::Group.where(default_group: true).each do |g|
        Regit::Groups::add_to_group(member, g.id)
      end

      member.modify_roles(new_roles, [])

      unless Regit::School::summer?(server.school)
        handle_advisement_system(member)
        handle_course_channels(member)
      end

      VERIFY_CODES.delete(member.info.username)

      # Announce it
      Regit::Utilities::announce(member.server, 'Please welcome a new member to the server!', true)
      Regit::Utilities::announce(member.server, nil).send_embed do |embed|
        embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: member.info.pictureurl)
        embed.title = '[Student] ' + member.info.first_name + ' ' + member.info.last_name
        embed.add_field(name: 'School', value: member.info.school.title + ' ' + member.info.school.school_type, inline: true)
        
        if Regit::School::summer?(server.school)
          embed.add_field(name: 'Class of', value: "'18", inline: true)
        else
          embed.add_field(name: 'Advisement', value: member.info.advisement, inline: true)
        end
      
        embed.add_field(name: 'Discord Tag', value: "#{member.mention} | #{member.distinct}", inline: true)
        embed.add_field(name: 'Birthday', value: member.info.birthday.strftime('%B %e, %Y '), inline: true)

        embed.color = 7380991

        embed.url = "http://www.getontrac.info:4567/users/#{member.info.username}"
        embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Joined at #{member.joined_at}", icon_url: member.avatar_url)
      end

      LOGGER.info 'Done!'

      member
    end
  end
end