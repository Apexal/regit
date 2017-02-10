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

        #Send email
        Regit::Email::GMAIL.deliver! do
          to email
          from "Student Discord Server"
          subject "Verify Your Identity"
          html_part do
            content_type 'text/html; charset=UTF-8'
            body "<h1>So Close!</h1><p>#{student.first_name}, your special verification code is <code>#{code}</code>.</p></p>Simply enter that code on <a href='http://www.getontrac.info:4567'>the server website</a> or reply to <b>studybot</b> on the server with <code>!verify #{code}</code>.</p>"
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
          Regit::Registration::setup_user(student.member)
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