module Regit
  module Events
    # Notifies user that bot is ready to use.
    module Ready
      extend Discordrb::EventContainer
      extend StoreData

      ready do |event|
        BOT.game = '!help'

        LOGGER.info 'Setting up...'
        # Set up voice states already
        event.bot.servers.each do |server_id, server|
          LOGGER.info "for #{server.name}..."

          Regit::BOT.set_role_permission(server.roles.find { |r| r.name == 'Students' }.id, 1)
          Regit::BOT.set_role_permission(server.roles.find { |r| r.name == 'Moderators' }.id, 2)
          Regit::BOT.set_user_permission(152621041976344577, 3) # Me
          
          Regit::VoiceChannels::setup_server_voice(server)

          begin
            Regit::Utilities::clean_channels(server)
          rescue => e
            LOGGER.error "Failed to clean channels"
            LOGGER.error e
          end
        end

        Regit::Schedule::update_work_channel_topic()
        LOGGER.info 'Regit is ready.'
        # Regit::WebApp.run!

        # Regit::Email::GMAIL.deliver do
        #   to "fmatranga18@regis.org"
        #   from "Student Discord Server"
        #   subject "Bot Started"
        #   html_part do
        #     content_type 'text/html; charset=UTF-8'
        #     body "<p>Regit has started.</p>"
        #   end
        # end
      end
    end
  end
end
