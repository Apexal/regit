# Example command module

module Regit
  module Commands
    module Colors
      extend Discordrb::Commands::CommandContainer

      command(:color, min_args: 0, max_args: 1, description: 'Choose a user color.', usage: '`!color #colorhex` or `!color`', permission_level: 1) do |event, color_hex|
        event.message.delete unless event.channel.private?
        if event.channel.private?
          event.user.pm 'You can only use `!color` on a school server!'
          return
        end

        color_hex ||= '#99AAB5'
        begin
          color_hex = color_hex.gsub('#', '').upcase
          raise unless color_hex =~ /^[0-9A-F]+$/i
          color = Discordrb::ColorRGB.new(color_hex.to_i(16))

          old_colors = event.server.roles.select { |r| r.association == :color && r.name != "##{color_hex}" }

          color_role = []
          unless color_hex == '99AAB5'
            color_role = event.server.roles.find { |r| r.name == "##{color_hex}" }
            if color_role.nil?
              color_role = event.server.create_role
              color_role.color = color
              color_role.name = "##{color_hex}"
            end
          end

          event.user.modify_roles(color_role, old_colors)
          event.channel.send_temporary_message('Changed user color! Remove color with just `!color`.', 5)
        rescue => e
          event.channel.send_temporary_message('Invalid hex color code! Trying getting codes from http://www.colorpicker.com', 10)
          LOGGER.error e
        end
        begin;event.server.roles.select { |r| r.association == :color && event.server.members.select { |m| m.role?(r) }.empty? }.map(&:delete);rescue;end;

        nil
      end
    end
  end
end