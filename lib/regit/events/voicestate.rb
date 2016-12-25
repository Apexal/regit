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
          channel.name = "Room Fun" # Name after teacher
          
          # THIS IS BEFORE handle_associated_channel TO MAKE IT LOOK FASTER
          # Create new empty room
          new_room = channel.server.create_channel(CONFIG.new_room_name, 2)

          handle_associated_channel(channel, user)          
        elsif channel.association == :room && channel.name != CONFIG.new_room_name && channel.users.empty?
          channel.delete
        end
      end
      
      def self.handle_associated_channel(voice_channel, member = nil)
        return unless voice_channel.type == 2
        return if !voice_channel.server.afk_channel.nil? && voice_channel == voice_channel.server.afk_channel 
        
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

          # For when a user creates a new room, it makes it seem less glitchy
          text_channel.define_overwrite(member, text_perms, 0) unless member.nil?

          text_channel.define_overwrite(voice_channel.server.roles.find { |r| r.id == voice_channel.server.id }, 0, text_perms)
          CHANNEL_ASSOCIATIONS[voice_channel.server.id][voice_channel.id] = text_channel.id
        end

        return text_channel
      end

      def self.handle_channel_action(action, member, old_channel = nil)
        text_perms = Discordrb::Permissions.new
        text_perms.can_read_message_history = true
        text_perms.can_read_messages = true
        text_perms.can_send_messages = true

        v_id = (old_channel.nil? ? member.voice_channel.id : old_channel.id)
        text_channel = member.server.text_channels.find { |t| t.id == CHANNEL_ASSOCIATIONS[member.server.id][v_id] }

        unless text_channel.nil?
          if action == :leave
            text_channel.send_message("**#{member.display_name}** *has left the voice-channel.*")
            text_channel.define_overwrite(member, 0, 0)
          elsif action == :join
            text_channel.send_message("**#{member.display_name}** *has joined the voice-channel.*")
            text_channel.define_overwrite(member, text_perms, 0)
          end
        end
      end

      voice_state_update do |event|
        old = OLD_VOICE_STATES[event.server.id]
        states = simplify_voice_states(event.server.voice_states)
        user = event.user.on(event.server)

        if old != states
          # Person changed voice-channel
          
          # How?
          if old[user.id].nil?
            # Connected to voice
            LOGGER.info "#{user.distinct} joined #{states[user.id].name}"
          elsif states[user.id].nil?
            # Disconnected from voice
            LOGGER.info "#{user.distinct} disconnected from #{old[user.id].name}"
          else
            # Changed rooms
            LOGGER.info "#{user.distinct} moved from #{old[user.id].name} to #{states[user.id].name}"
          end

          unless old[user.id].nil?
            handle_voice_channel(old[user.id], user)
            handle_channel_action(:leave, user, old[user.id]) unless old[user.id].association == :room && old[user.id].users.empty?
          end

          unless states[user.id].nil?
            handle_voice_channel(states[user.id], user)
            handle_channel_action(:join, user)
          end
        end

        OLD_VOICE_STATES[event.server.id] = states.clone
      end

      # When voice-channels are created (by users or by the bot) handle their associated #voice-channel
      channel_create do |event|
        handle_associated_channel(event.channel) if event.type == 2 && event.name != CONFIG.new_room_name
      end

      channel_delete do |event|
        if event.type == 2 # Voice
          # Hierarchy stuff
          begin
            event.server.text_channels.find { |t| t.id == CHANNEL_ASSOCIATIONS[event.server.id][event.id] }.delete
            CHANNEL_ASSOCIATIONS[event.server.id].delete event.id
          rescue NoMethodError
            # Did not have an associated text-channel for whatever reason (fine)
          end
        elsif event.type == 0
          # Delete association
          begin
            CHANNEL_ASSOCIATIONS[event.server.id][event.server.id].delete(CHANNEL_ASSOCIATIONS[event.server.id][event.server.id].key(event.id))
          rescue
            # Did not have an association (rightfully deleted then)
          end
        end
      end

    end
  end
end