module Regit
  module Commands
    module SetupServer
      extend Discordrb::Commands::CommandContainer
      extend StoreData

      command(:setup, description: 'Open console.', permission_level: 3) do |event|
        #return 'This server is already setup!' if event.server.setup?
        
        # Will create all roles necessary
        LOGGER.info 'Setting up new server...'
        event.server.owner.pm 'Adding necessary roles...'

        DEFAULT_ROLES.each do |role_name, info|
          role = nil
          
          if role_name == 'everyone'
            role = event.server.roles.find { |role| role.id == event.server.id }
          elsif !event.server.roles.find { |r| r.name == role_name }.nil?
            LOGGER.info "Role #{role_name} already exists"
            next
          end

          # Create the role and assign it the default perms
          role = event.server.create_role if role.nil?
          role.name = role_name
          role.hoist = info['hoist']
          
          # Does not work yet
          role.mentionable = info['mentionable']

          perms = Discordrb::Permissions.new

          info['perms'].each do |perm|
            perms.send("can_#{perm}=", true)
          end

          role.packed = perms.bits

          event.server.owner.pm "Added role **#{role_name}** with info: #{info.inspect}"
        end

        # Text-channels
        DEFAULT_TEXT_CHANNELS.each do |channel_name, info|
          unless event.server.text_channels.find { |t| t.name == channel_name }.nil?
            LOGGER.info "Text-channel ##{channel_name} already exists."
            next
          end

          channel = info['default'] ? event.server.default_channel : event.server.create_channel(channel_name)
          channel.name = channel_name
          channel.topic = info['topic']
          channel.position = info['position'] unless info['position'].nil?

          unless info['text'].nil?
            channel.split_send(info['text'])
          end

          # Channel perms
          info['perms'].each do |role_name, perms|
            role = event.server.roles.find { |r| r.name == role_name }
            role = event.server.roles.find { |r| r.id == event.server.id } if role_name == 'everyone'

            if role.nil?
              LOGGER.info "Role #{role_name} doesn't exist. Skipping..."
              next
            end

            p = Regit::Utilities::list_to_perms(perms)
            channel.define_overwrite(role, p[:allow], p[:deny])
          end
        end

        # Voice-channels
        DEFAULT_VOICE_CHANNELS.each do |channel_name, info|
          unless event.server.voice_channels.find { |v| v.name == channel_name }.nil?
            LOGGER.info "Voice-channel #{channel_name} already exists on #{event.server.name}!"  
            next
          end

          channel = event.server.create_channel(channel_name, 2)
          channel.position = info['position'] unless info['position'].nil?

          # Channel perms
          info['perms'].each do |role_name, perms|
            role = event.server.roles.find { |r| r.name == role_name }
            role = event.server.roles.find { |r| r.id == event.server.id } if role_name == 'everyone'

            if role.nil?
              LOGGER.info "Role #{role_name} doesn't exist. Skipping..."
              next
            end

            p = Regit::Utilities::list_to_perms(perms)
            channel.define_overwrite(role, p[:allow], p[:deny])
          end

          event.server.owner.pm "Added voice-channel **#{channel_name}**"
        end

        'Done!'
      end
    end
  end
end