module Regit
  module Events
    # Notifies user that bot is ready to use.
    module Ready
      extend Discordrb::EventContainer
      extend StoreData
      
      associations = load_file("#{Dir.pwd}/data/associations.yaml")

      ready do |event|
        BOT.game = 'with Data'

        text_perms = Discordrb::Permissions.new
        text_perms.can_read_message_history = true
        text_perms.can_read_messages = true
        text_perms.can_send_messages = true

        LOGGER.info 'Setting up...'
        # Set up voice states already
        event.bot.servers.each do |server_id, server|
          LOGGER.info "for #{server.name}..."

          Regit::BOT.set_role_permission(server.roles.find { |r| r.name == 'Students' }.id, 1)
          Regit::BOT.set_role_permission(server.roles.find { |r| r.name == 'Moderators' }.id, 2)
          Regit::BOT.set_user_permission(152621041976344577, 3) # Me
          
          Regit::OLD_VOICE_STATES[server_id] = Regit::Events::VoiceState::simplify_voice_states(server.voice_states)
          
          CHANNEL_ASSOCIATIONS[server.id] = ( associations.nil? || associations[server_id].nil? ? {} : associations[server_id] )

          CHANNEL_ASSOCIATIONS[server.id].select { |v_id, _| server.voice_channels.find { |v| v.id == v_id }.nil? }.each { |v_id, _| CHANNEL_ASSOCIATIONS[server.id].delete(v_id) } # Remove extra associations
          server.text_channels.select { |t| t.association == :voice_channel && !CHANNEL_ASSOCIATIONS[server_id].has_value?(t.id) }.map(&:delete)

          server.voice_channels.each do |v|
            next if v.name == !server.afk_channel.nil? && v == server.afk_channel
            t_channel = Regit::Events::VoiceState::handle_voice_channel(v)

            v.users.each do |u|
              t_channel.define_overwrite(u, text_perms, 0)
            end

            # Account for people in #voice-channel's they arent supposed to be in
            t_channel.users.select { |u| u.student?(server.school) && !v.users.include?(u) }.map { |u| t_channel.define_overwrite(u, 0, 0) } unless t_channel.nil?
          end
          Regit::Utilities::clean_channels(server)
        end

        Regit::Schedule::update_work_channel_topic()

        LOGGER.info 'Regit is ready.'
      end
    end
  end
end