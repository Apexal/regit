module Regit
  module Commands
    module RegistrationCommands
      extend Discordrb::Commands::CommandContainer

      command(:register, description: 'Start the registration process.', min_args: 1, max_args: 1, usage: '`!register schoolusername`') do |event, email|
        # Sanitize email
        email.strip!

        # Validate and get code
        begin
          code = Regit::Registration::start_process(event.user, email.split('@')[0])
        rescue => e
          event.user.pm(e)
          return
        end

        student = Regit::Database::Student.find_by_username(email.split('@')[0])

        # Send email
        Regit::Email::GMAIL.deliver! do
          to email
          from "Student Discord Server"
          subject "Verify Your Identity"
          html_part do
            content_type 'text/html; charset=UTF-8'
            body "<h1>So Close!</h1><p>#{student.first_name}, your special verification code is <code>#{code}</code>.</p></p>Simply reply to <b>studybot</b> on the server with <code>!verify #{code}</code>.</p>"
            #body "<h1>So Close!</h1><p>#{student.first_name}, your special verification code is <code>#{code}</code>.</p></p>Simply enter that code on <a href='http://www.getontrac.info:4567'>the server website</a> or reply to <b>studybot</b> on the server with <code>!verify #{code}</code>.</p>"
          end
        end
        
        event.user.pm("**Great!** :ok_hand: \nJust check your school email and you'll be ready!")

        nil
      end

      command(:verify, description: 'Verify your identity!', min_args: 1, max_args: 1, usgae: '`!verify code`') do |event, code|
        # Link
        student = Regit::Registration::verify_student(event.user, code)

        # FINISH HIM
        message = event.user.pm('Setting you up...')

        begin
          member = student.member

          Regit::Registration::setup_user(member)

          # Announce it
          Regit::Utilities::announce(member.server, 'Please welcome a new member to the server!', true)
          Regit::Utilities::announce(member.server, nil).send_embed do |embed|
            embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: student.pictureurl)
            embed.title = '[Student] ' + student.first_name + ' ' + student.last_name
            embed.add_field(name: 'School', value: student.school.title + ' ' + student.school.school_type, inline: true)
            
            if Regit::School::summer?(server.school)
              embed.add_field(name: 'Class of', value: student.graduation_year, inline: true)
            else
              embed.add_field(name: 'Advisement', value: student.advisement, inline: true)
            end
          
            embed.add_field(name: 'Discord Tag', value: "#{member.mention} | #{member.distinct}", inline: true)
            embed.add_field(name: 'Birthday', value: student.birthday.strftime('%B %e, %Y '), inline: true)

            embed.color = 7380991

            embed.url = "http://www.getontrac.info:4567/users/#{student.username}"
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Joined at #{member.joined_at}", icon_url: member.avatar_url)
          end

          # Send email
          Regit::Email::GMAIL.deliver! do
            to email
            from 'Student Discord Server'
            subject "Welcome to the Server, #{student.first_name}"
            html_part do
              content_type 'text/html; charset=UTF-8'
              body "<h1>Welcome to the Server!</h1>"
            end
          end
        rescue => e
          message.edit(e)
          return
        end
        message.edit('**DONE!**')
        nil
      end
    end
  end
end