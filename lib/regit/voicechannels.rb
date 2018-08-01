module Regit
  module VoiceChannels
    extend StoreData

    # These are the perms given to people for a associated voice-channel
    TEXT_PERMS = Discordrb::Permissions.new
    TEXT_PERMS.can_read_message_history = true
    TEXT_PERMS.can_read_messages = true
    TEXT_PERMS.can_send_messages = true

    VOICE_PERMS = Discordrb::Permissions.new
    VOICE_PERMS.can_connect = true

    FULL_VOICE_PERMS = Discordrb::Permissions.new
    FULL_VOICE_PERMS.can_connect = true
    FULL_VOICE_PERMS.can_use_voice_activity = true
    FULL_VOICE_PERMS.can_speak = true

    # VOTEKICK CONSTANTS
    VOTEKICK_THRESHOLD = 0.75

    def self.save_associations
      save_to_file("#{Dir.pwd}/data/associations.yaml", CHANNEL_ASSOCIATIONS)
      save_to_file("#{Dir.pwd}/data/channel_owners.yaml", CHANNEL_OWNERS)
    end

    def self.trim_voice_associations(server)
      CHANNEL_ASSOCIATIONS[server.id].each do |vc_id, tc_id|
        CHANNEL_ASSOCIATIONS[server.id].delete(vc_id) if tc_id.nil? || server.voice_channels.find { |vc| vc.id == vc_id }.nil?
      end
      save_associations
    end

    def self.setup_server_voice(server)
      LOGGER.info "Setting up voice system for [#{server.name}]"
      
      CHANNEL_OWNERS[server.id] = Hash.new

      LOGGER.info 'Trimming associations'
      trim_voice_associations(server)

      LOGGER.info 'Cleaning up after restart...'

      # Loop through existing #voice-channel text channels and make sure they are associated or delete them
      server.text_channels.select { |tc| tc.association == :voice_channel }.each do |tc|
        LOGGER.info "At #{tc.name} (#{tc.id})"
        unless CHANNEL_ASSOCIATIONS[server.id].values.include?(tc.id)
          # Not associated
          tc.delete
          LOGGER.info 'Deleted an orphaned #voice-channel'
          next
        end

        vc = server.voice_channels.find { |vc| vc.id == CHANNEL_ASSOCIATIONS[server.id].key(tc) } # Associated voice-channel

        #tc.users.select { |u| u.defined_permission?(:send_messages, tc) && !vc.users.include?(u) }.each do |u| # TODO: FIX WHEN tc.users IS FIXED
          # LOGGER.info(u.distinct)
          # Users not in the voice channel but somehow in the #voice-channel text channel
          #tc.define_overwrite(u, 0, 0) # Effectively removes their perms to see the #voice-channel
        #end
      end

      LOGGER.info 'Associating...'
      server.voice_channels.select { |vc| vc.name != Regit::CONFIG.new_room_name }.each do |vc| 
        if vc.association == :room && vc.users.empty?
          vc.delete
          LOGGER.info "Deleted empty room #{vc.name}"
          next
        end
        associate_voice_channel(vc)
      end

      LOGGER.info 'Done'
    end

    def self.associate_voice_channel(voice_channel, user=nil)
      server = voice_channel.server
      return if voice_channel == server.afk_channel # No need for AFK channel to have associated text-channel
      puts "Associating '#{voice_channel.name} / #{server.name}'"
      
      text_channel = server.text_channels.find { |tc| tc.id == CHANNEL_ASSOCIATIONS[server.id][voice_channel.id] }

      need_text_channel = CHANNEL_ASSOCIATIONS[server.id][voice_channel.id].nil? || text_channel.nil?

      # Do this first so if two people join a [New Room] at the same time it recognizes that and doesnt try to associate twice
      if need_text_channel
        text_channel = server.create_channel('voice-channel', 0) # Creates a matching text-channel called 'voice-channel'
        category = voice_channel.server.channels.find { |c| c.name == 'Voice Channels' }
        text_channel.category= category
        text_channel.position = 0
        CHANNEL_ASSOCIATIONS[server.id][voice_channel.id] = text_channel.id # Associate the two 
      end

      create_new_room(voice_channel, user) if voice_channel.name == Regit::CONFIG.new_room_name && !voice_channel.users.empty?

      if need_text_channel
        topic = "Private chat for all those in the voice-channel [**#{voice_channel.name}**]"
        
        transfer_room_ownership(voice_channel, user) unless voice_channel.student_owner.nil?
        
        text_channel.topic = topic
        # Give each voice channel member perms to see the new associated text-channel
        voice_channel.users.each do |u|
          text_channel.define_overwrite(u, TEXT_PERMS, 0)
        end

        text_channel.define_overwrite(voice_channel.server.roles.find { |r| r.id == voice_channel.server.id }, 0, TEXT_PERMS) # Set default perms as invisible
        
        save_associations
      end

      text_channel
    end

    def self.handle_user_change(action, voice_channel, user)
      puts "Handling user #{action} for '#{voice_channel.name} / #{voice_channel.server.name}' for #{user.distinct}"
      text_channel = associate_voice_channel(voice_channel, user) # This will create it if it doesn't exist. Pretty cool!

      # For whatever reason, maybe is AFK channel
      return if text_channel.nil?

      if action == :join
        text_channel.send_message("#{user.short_info} joined the voice-channel.")
        text_channel.define_overwrite(user, TEXT_PERMS, 0)
      else
        return voice_channel.delete if voice_channel.users.empty? && voice_channel.association == :room

        text_channel.send_message("#{user.short_info} left the voice-channel.")
        text_channel.define_overwrite(user, 0, 0)
        
        # Give ownership to oldest member if owner left
        transfer_room_ownership(voice_channel, voice_channel.users.sort_by { |u| u.on(voice_channel.server).joined_at }.first) if voice_channel.student_owner == user
      end
    end

    def self.rename_room(voice_channel, new_name)
      raise 'Not a voice room' unless voice_channel.association == :room

      new_name.strip!
        
      max_length = 100 - 'Room '.length # 95; easy to change later on
      new_name = new_name[0..max_length-1]

      raise 'Invalid name' if new_name.empty?

      voice_channel.name = "Room #{new_name}"
      voice_channel.associated_channel.topic = "Private chat for all those in the voice-channel [**#{voice_channel.name}**] | Owned by #{voice_channel.student_owner.mention}"
      
      new_name
    end

    def self.toggle_ban_from_voice(channel, target, user=nil)
      raise 'This channel doesn\'t have an owner...' if channel.student_owner.nil?
      
      # Check for mention(s)
      raise 'You must say what users you want to toggle ban! `!vban @user1`' if target.nil?
      
      perms = Discordrb::Permissions.new
      perms.can_connect = true

      # Kick target (set override)
      if target.permission?(:connect, channel)
        # Ban
        channel.define_overwrite(target, 0, perms)
        target.pm("You've been banned from **#{channel.name} / #{channel.server.name}**")
        kick_from_voice(channel, [target], user)
        LOGGER.info "Banned #{target.distinct} from #{channel.name} / #{channel.server.name}"
        return true
      else
        # Unban
        channel.define_overwrite(target, 0, 0)
        target.pm("You've been unbanned from **#{channel.name} / #{channel.server.name}**")
        
        LOGGER.info "Unbanned #{target.distinct} from #{channel.name} / #{channel.server.name}"
        return false
      end
    end

    def self.kick_from_voice(channel, targets, user=nil)
      #raise 'This channel doesn\'t have an owner...' if channel.student_owner.nil?
      
      # Check for mention(s)
      raise 'You must say what users you want to kick! `!vkick @user1 @user2`' if targets.empty?
      
      # Kick every target (move to AFK channel)
      kicked = []
      targets.each do |target|
        next if target == user || target.on(channel.server).voice_channel != channel
        kicked << target
        channel.server.move(target, channel.server.afk_channel)
      end
      
      kicked
    end

    # Start a vote kick and send the embed message with the mentions
    def self.start_vote_kick(voice_channel, started_by, target)
      raise 'Not a voice room.' unless voice_channel.association == :room
      raise 'Can\'t votekick yourself.' if started_by == target
      raise 'Target isn\'t in voice-channel.' unless voice_channel.users.include?(target)
      raise 'Not enough people in voice-channel.' if voice_channel.users.length < 3

      VOTEKICKS[voice_channel.server.id][voice_channel.id] ||= []

      # Check for existing
      raise 'Somebody already started a votekick for this person!' if VOTEKICKS[voice_channel.server.id][voice_channel.id].count { |v| v[:target] == target } > 0

      votes = VOTEKICKS[voice_channel.server.id][voice_channel.id] << { target: target, message: nil }
      vote = votes.find { |v| v[:target] == target}

      title = target.info.nil? ? target.display_name : target.info.short_description

      embed = Discordrb::Webhooks::Embed.new
      embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: "Vote Kick #{title}", url: nil, icon_url: target.safe_avatar_url)
      embed.description = "Vote to kick #{target.mention} from this voice-channel by choosing the ❌ or ☑ reaction below."
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Started by #{started_by.short_info}", icon_url: started_by.safe_avatar_url)

      message = voice_channel.associated_channel.send_embed('@everyone', embed)
      message.react('☑')
      message.react('❌')

      vote[:message] = message
    end

    def self.handle_vote_kick(target)
      vc = target.voice_channel
      vote = VOTEKICKS[vc.server.id][vc.id].find { |v| v[:target] == target }
      raise 'No vote kick of the target currently exists' if vote.nil?

      message = vote[:message].channel.load_message(vote[:message].id)
      total = vc.users.length

      yes = message.reactions['☑'].count - 1
      no = message.reactions['❌'].count - 1

      yes_percent = yes / total.to_f
      no_percent = no / total.to_f

      if yes_percent >= VOTEKICK_THRESHOLD
        begin
          kick_from_voice(vc, [target])
          message.edit("#{target.mention} has been votekicked! (#{yes_percent * 100}% voted yes)")
          target.pm "You have been votekicked from **#{vc.name}**."
          message.delete_all_reactions
          VOTEKICKS[vc.server.id][vc.id].delete_if { |v| v[:target] == target }
        rescue => e
          LOGGER.error "Failed to votekick user: #{e}"
          LOGGER.error e.backtrace.join("\n")
          vote[:message].channel.send_message("Failed to kick...")
        end
      elsif no_percent >= VOTEKICK_THRESHOLD
        VOTEKICKS[vc.server.id][vc.id].delete_if { |v| v[:target] == target }

        message.edit("#{target.mention} has **not** been votekicked! (#{no_percent * 100}% voted no)")
        message.delete_all_reactions
      end

      LOGGER.info "Vote to kick #{target.display_name} from #{vc.name}: #{yes_percent * 100}% yes (#{yes}/#{total})"
    end

    # Toggle whether or not to allow Guests in a voice room
    def self.set_room_guests(voice_channel, allow=true)
      raise 'Not a voice room.' unless voice_channel.association == :room

      guests_role = voice_channel.server.roles.find { |r| r.name == 'Guests' }

      if allow
        voice_channel.define_overwrite(guests_role, FULL_VOICE_PERMS, 0)
      else
        voice_channel.define_overwrite(guests_role, 0, 0)
      end

      LOGGER.info "Guests in #{voice_channel.name} / #{voice_channel.server.name}: #{allow}"

      allow
    end

    def self.transfer_room_ownership(voice_channel, new_owner)
      CHANNEL_OWNERS[voice_channel.server.id][voice_channel.id] = new_owner.id
      text_channel = voice_channel.associated_channel

      text_channel.topic = "Private chat for all those in the voice-channel [**#{voice_channel.name}**] | Owned by #{voice_channel.student_owner.mention}"
      
      help = [
        "**#{voice_channel.student_owner.mention}, now owns this voice channel.**\n", 
        "Use `!vkick @user1 @user2 ...` to kick users from the voice channel.",
        "Use `!vban @user` to toggle ban for one user from the voice channel.",
        "Use `!allowguests` and `!denyguests` to allow/prevent Guests from entering the voice channel."
      ]

      text_channel.send_message(help.join "\n")
    end

    def self.create_new_room(voice_channel, user=nil)
      # Give them ownership of associated text-channel 
      CHANNEL_OWNERS[voice_channel.server.id][voice_channel.id] = user.id unless user.nil?
      save_associations

      if !user.nil? && user.studying?
        voice_channel.name = "Study Room Fun" # TODO: Better filler
        voice_channel.define_overwrite(voice_channel.server.roles.find { |r| r.name == 'Studying' }, VOICE_PERMS, 0)
        voice_channel.define_overwrite(voice_channel.server.roles.find { |r| r.id == voice_channel.server.id }, 0, VOICE_PERMS)
      else
        # If user is playing a game, name room after game
        unless user.nil? || user.game.nil?
          voice_channel.name = "Room #{user.game[0..20]}"
        else
          voice_channel.name = 'Room ' + (user.nil? || !user.student?(voice_channel.server.school) ? voice_channel.server.school.staffs.order("RAND()").first : user.info.teachers.sample ).last_name  # Name after teacher
        end

        # Block now to studying users
        voice_channel.define_overwrite(voice_channel.server.roles.find { |r| r.name == 'Studying' }, 0, VOICE_PERMS)
      end
      voice_channel.user_limit = nil

      # THIS IS BEFORE handle_associated_channel TO MAKE IT LOOK FASTER
      # Create new empty room
      new_room = voice_channel.server.create_channel(CONFIG.new_room_name, 2)
      category = voice_channel.server.channels.find { |c| c.name == 'Voice Channels' }
      new_room.category= category
      new_room.user_limit = 1
    end
  end
end
