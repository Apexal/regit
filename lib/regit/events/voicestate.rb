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
          channel.name = "Room Fun" # Name after teacher
          
          # THIS IS BEFORE handle_associated_channel TO MAKE IT LOOK FASTER
          # Create new empty room
          new_room = channel.server.create_channel(CONFIG.new_room_name, 2)
          new_room.association = :new_room

          handle_associated_channel(channel, user)          
        elsif channel.name != CONFIG.new_room_name && channel.users.empty?
          channel.delete if channel.association == :room
        end
      end
      
      def self.handle_associated_channel(voice_channel, member = nil)
        return unless voice_channel.type == 2
        return if !voice_channel.server.afk_channel.nil? && voice_channel == voice_channel.server.afk_channel 
        
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

          # For when a user creates a new room, it makes it seem less glitchy
          text_channel.define_overwrite(member, text_perms, 0) unless member.nil?

          text_channel.define_overwrite(voice_channel.server.roles.find { |r| r.id == voice_channel.server.id }, 0, text_perms)
          CHANNEL_ASSOCIATIONS[voice_channel.server.id][voice_channel.id] = text_channel.id
        end

        return text_channel
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
          text_channel.send_message("**#{member.display_name}** *has left the voice-channel.*")
          text_channel.define_overwrite(member, 0, text_perms)
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
          # This order prevents the person joining from seeing the message
          text_channel.send_message("**#{member.display_name}** *has joined the voice-channel.*")
          text_channel.define_overwrite(member, text_perms, 0)
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
            handle_leave_channel(user, old[user.id]) unless old[user.id].association == :room && old[user.id].users.empty?
          end

          unless states[user.id].nil?
            handle_voice_channel(states[user.id], user)
            handle_join_channel(user)
          end
        end

        OLD_VOICE_STATES[event.server.id] = states.clone
      end

      channel_create do |event|
        if event.type == 2 && event.name != CONFIG.new_room_name
          #return if event.channel.id == event.server.afk_channel.id
          handle_associated_channel(event.channel)
        end
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