module Regit
  module Groups
    def self.group_embed(group)
      Discordrb::Webhooks.Builder.new.add_embed do |embed|
        embed.title 'Test'
      end
    end

    def self.delete_group(id)
      group = Regit::Database::Group.find(id)

      # SO EZ
      group.school.server.members.select { |m| m.role? group.role }.each { |m| m.pm "**Group #{group.name}** has been deleted." }
      group.role.delete
      group.text_channel.delete

      LOGGER.info "Deleted group #{group.name} of #{group.school.title} server"
      group.destroy
    end

    def self.create_group(owner, full_name, description, is_private)
      full_name.strip!
      raise '' if full_name.empty?

      server = owner.server

      # Prepare data
      full_name = full_name[0..20]

      # Check if already exists
      raise "Group #{full_name} already exists!" if Regit::Database::Group.where(name: full_name).count > 0

      description = description.empty? ? 'No description given.' : description[0..254]
      group_name = full_name.dup
      group_name.downcase!
      group_name.gsub!(/\s+/, '-')
      group_name.gsub!(/[^\p{Alnum}-]/, '')

      raise "Group name '#{full_name}' is too short!" if group_name.length < 3

      # Perms for group members
      group_perms = Discordrb::Permissions.new
      group_perms.can_read_messages = true
      group_perms.can_read_message_history = true
      group_perms.can_send_messages = true
      group_perms.can_mention_everyone = true

      # Perms for non-group members
      non_perms = Discordrb::Permissions.new
      non_perms.can_read_messages = true

      # Group owner perms
      owner_perms = Discordrb::Permissions.new
      owner_perms.can_manage_messages = true

      # Create role
      group_role = server.create_role
      group_role.name = full_name
      group_role.mentionable = true
      owner.add_role(group_role)

      # Create text-channel
      group_text_channel = server.create_channel(group_name, 0)
      group_text_channel.topic = description
      group_text_channel.define_overwrite(group_role, group_perms, 0) # Allow group members to use it
      group_text_channel.define_overwrite(owner, owner_perms, 0) # Add owner perms
      group_text_channel.define_overwrite(server.roles.find { |r| r.id == server.id }, 0, non_perms) # Don't allow anyone else

      group = Regit::Database::Group.create(school_id: server.school.id, name: full_name, private: is_private, owner_username: owner.info.username, description: description, default_group: false, text_channel_id: group_text_channel.id, role_id: group_role.id, voice_channel_allowed: false)
      LOGGER.info "Attempting to create group '#{group_name}'"
      return group
    end

    def self.remove_from_group(member, group_id)
      return unless member.student?(member.server.school)

      group = Regit::Database::Group.find(group_id)
      raise 'Group doesn\'t exist!' if group.nil?

      raise 'Not in that group.' unless member.role? group.role

      group.text_channel.send_message "*#{member.mention} left the group.*"
      member.remove_role group.role

      return group
    end
  end
end