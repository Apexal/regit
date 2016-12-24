module Regit
  module Events
    # Notifies user that bot is ready to use.
    module Ready
      extend Discordrb::EventContainer
      extend StoreData
      
      associations = load_file("#{Dir.pwd}/data/associations.yaml")

      ready do |event|
        BOT.game = 'with the Future'
        LOGGER.info 'Regit is ready.'

        text_perms = Discordrb::Permissions.new
        text_perms.can_read_message_history = true
        text_perms.can_read_messages = true
        text_perms.can_send_messages = true

        # Set up voice states already
        event.bot.servers.each do |server_id, server|
          Regit::OLD_VOICE_STATES[server_id] = Regit::Events::VoiceState::simplify_voice_states(server.voice_states)
          
          CHANNEL_ASSOCIATIONS[server.id] = ( associations.nil? || associations[server_id].nil? ? {} : associations[server_id] )

          server.text_channels.select { |t| t.association == :voice_channel && !CHANNEL_ASSOCIATIONS[server_id].has_value?(t.id) }.map(&:delete)

          server.voice_channels.each do |v|
            next if v.name == CONFIG.new_room_name || (!server.afk_channel.nil? && v == server.afk_channel)
            t_channel = Regit::Events::VoiceState::handle_associated_channel(v)

            v.users.each do |u|
              t_channel.define_overwrite(u, text_perms, 0)
            end

            # Account for people in #voice-channel's they arent supposed to be in
            t_channel.users.select { |u| u.student?(server.school) && !v.users.include?(u) }.map { |u| t_channel.define_overwrite(u, 0, 0) }  
          end

          CHANNEL_ASSOCIATIONS[server.id].select { |v_id, _| server.voice_channels.find { |v| v.id == v_id }.nil? }.map(&:delete) # Remove extra associations
        end
      end
    end
  end
end