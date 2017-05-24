# Example command module

module Regit
  module Commands
    module Colors
      extend Discordrb::Commands::CommandContainer
      
      # Allows users to have any color role that they want
      command(:color, min_args: 0, max_args: 1, description: 'Choose a user color.', usage: '`!color #colorhex` or `!color`', permission_level: 1, permission_message: 'You can only use this command in a school server!') do |event, color_hex|
        event.message.delete unless event.channel.private?

        color_hex ||= '#99AAB5' # Default color
        begin
          color_hex = color_hex.gsub('#', '').upcase
          raise unless color_hex =~ /^[0-9A-F]+$/i
          color = Discordrb::ColorRGB.new(color_hex.to_i(16))

          old_colors = event.server.roles.select { |r| r.association == :color && r.name != "##{color_hex}" }

          color_role = []
          unless color_hex == '99AAB5' # Unless its the default color, find/create the custom color role
            color_role = event.server.roles.find { |r| r.name == "##{color_hex}" }
            if color_role.nil?
              color_role = event.server.create_role
              color_role.color = color
              color_role.name = "##{color_hex}"
            end
          end

          event.user.modify_roles(color_role, old_colors)
          event.user.pm.send_message("Changed user color to #{color_hex}! Remove color with just `!color`.")
        rescue => e
          event.user.send_message('Invalid hex color code! Trying getting codes from http://www.colorpicker.com')
          LOGGER.error e
        end
        
        begin
          # Tries to remove any unused color roles
          event.server.roles.select { |r| r.association == :color && r.members.empty? }.map(&:delete)
        rescue
          LOGGER.log 'Failed to remove unused color roles...'
        end

        nil
      end
    end
  end
end
