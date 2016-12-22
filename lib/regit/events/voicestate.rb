module Regit
  module Events
    
    module VoiceState
      extend Discordrb::EventContainer
      extend StoreData

      text_perms = Discordrb::Permissions.new
      text_perms.can_read_message_history = true
      text_perms.can_read_messages = true
      text_perms.can_send_messages = true

      def self.simplify_voice_states(voice_states)
        simple = {}

        voice_states.each do |user_id, state|
          simple[user_id] = state.voice_channel
        end

        return simple
      end

      def self.handle_voice_channel(channel, user = nil)
        LOGGER.debug "Handling voice-channel #{channel.name} for #{user.distinct}"
        
        # Check what type of room it is
        if channel.name == CONFIG.new_room_name && !channel.users.empty?
          # Person joined empty voice-channel! Transform into room!
          channel.association = :room
          channel.name = "Room Fun"

          # Create new empty room
          channel.server.create_channel(CONFIG.new_room_name, 2)
        elsif channel.name != CONFIG.new_room_name && channel.users.empty?
          channel.delete if channel.association == :room
        end
      end
      
      def self.handle_associated_channel(voice_channel)
        return unless voice_channel.type == 2
        LOGGER.info "handle_associated_channel: #{voice_channel.name}"
        text_perms = Discordrb::Permissions.new
        text_perms.can_read_message_history = true
        text_perms.can_read_messages = true
        text_perms.can_send_messages = true

        text_channel = voice_channel.server.text_channels.find { |c| c.id == CHANNEL_ASSOCIATIONS[voice_channel.server.id][voice_channel.id] }
  
        if text_channel.nil?
          # Must create
          # Create associated #voice-channel text-channel
          text_channel = voice_channel.server.create_channel('voice-channel', 0)
          text_channel.topic = "Private chat for all those in the voice-channel **#{voice_channel.name}**."
          text_channel.define_overwrite(voice_channel.server.roles.find { |r| r.id == voice_channel.server.id }, 0, text_perms)
          CHANNEL_ASSOCIATIONS[voice_channel.server.id][voice_channel.id] = text_channel.id
        end

        voice_channel.users.each do |u|
          text_channel.define_overwrite(u, text_perms, 0)
        end

        return text_channel
      end

      def self.update_associations(server)
        LOGGER.info "update_associations"
        CHANNEL_ASSOCIATIONS[server.id].each do |v_id, t_id|
          voice_channel = server.voice_channels.find { |v| v.id == v_id }
          text_channel = server.text_channels.find { |t| t.id == t_id }

          if voice_channel.nil?
            text_channel.delete
          else
            handle_associated_channel(voice_channel)
          end
        end

        save_to_file("#{Dir.pwd}/data/associations.yaml", CHANNEL_ASSOCIATIONS)
      end

      def self.handle_leave_channel(member, old_channel)
        
        text_perms = Discordrb::Permissions.new
        text_perms.can_read_message_history = true
        text_perms.can_read_messages = true
        text_perms.can_send_messages = true

        v_id = old_channel.id
        text_channel = member.server.text_channels.find { |t| t.id == CHANNEL_ASSOCIATIONS[member.server.id][v_id] }

        if text_channel.nil?

        else
          text_channel.define_overwrite(member, 0, text_perms)
          text_channel.send_message("**#{member.display_name}** *has left the voice-channel.*")
        end
      end

      def self.handle_join_channel(member)
        text_perms = Discordrb::Permissions.new
        text_perms.can_read_message_history = true
        text_perms.can_read_messages = true
        text_perms.can_send_messages = true

        v_id = member.voice_channel.id
        text_channel = member.server.text_channels.find { |t| t.id == CHANNEL_ASSOCIATIONS[member.server.id][v_id] }

        if text_channel.nil?

        else
          text_channel.define_overwrite(member, text_perms, 0)
          text_channel.send_message("**#{member.display_name}** *has joined the voice-channel.*")
        end
      end

      voice_state_update do |event|
        old = OLD_VOICE_STATES[event.server.id]
        states = simplify_voice_states(event.server.voice_states)
        user = event.user.on(event.server)

        if old != states
          LOGGER.debug "Person moved..."
          # Person changed voice-channel
          # How?
          if old[user.id].nil?
            # Connected to voice
            LOGGER.info "#{user.distinct} joined #{states[user.id].name}"
            handle_join_channel(user)
          elsif states[user.id].nil?
            # Disconnected from voice
            LOGGER.info "#{user.distinct} disconnected from #{old[user.id].name}"
            handle_leave_channel(user, old[user.id])
          else
            # Changed rooms
            LOGGER.info "#{user.distinct} moved from #{old[user.id].name} to #{states[user.id].name}"
            handle_leave_channel(user, old[user.id])
            handle_join_channel(user)
          end

          handle_voice_channel(old[user.id], user) unless old[user.id].nil? 
          handle_voice_channel(states[user.id], user) unless states[user.id].nil?

          save_to_file("#{Dir.pwd}/data/associations.yaml", CHANNEL_ASSOCIATIONS)
        end

        OLD_VOICE_STATES[event.server.id] = states.clone
      end

      channel_create do |event|
        if event.type == 2
          #return if event.channel.id == event.server.afk_channel.id
          handle_associated_channel(event.channel)
          save_to_file("#{Dir.pwd}/data/associations.yaml", CHANNEL_ASSOCIATIONS)
        end
      end

      channel_delete do |event|
        if event.type == 2 # Voice
          # Hierarchy stuff
          event.server.text_channels.find { |t| t.id == CHANNEL_ASSOCIATIONS[event.server.id][event.id] }.delete
          CHANNEL_ASSOCIATIONS[event.server.id].delete event.id
        elsif event.type == 0
          # Delete association
          begin
            CHANNEL_ASSOCIATIONS[event.server.id][event.server.id].delete(CHANNEL_ASSOCIATIONS[event.server.id][event.server.id].key(event.id))
          rescue
            # Did not have an association (rightfully deleted then)
          end
        end

        save_to_file("#{Dir.pwd}/data/associations.yaml", CHANNEL_ASSOCIATIONS)
      end

    end
  end
end