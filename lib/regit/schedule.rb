module Regit
  module Schedule
    def self.update_work_channel_topic()
      # LOGGER.info 'Updating schedule day info...'
      basis = "#{DateTime.now.strftime('%A, %B %e')} | General school discussion, homework help, etc."
      Regit::BOT.servers.each do |id, server|
        work_channel = server.text_channels.find { |t| t.name == 'work' }
        next if work_channel.nil? # Somehow

        if Regit::School::summer?(server.school)
          work_channel.topic = "**SUMMER VACATION** | #{basis}"
        else
          today = SCHEDULE.today
          work_channel.topic = (today.nil? ? '**NO SCHOOL TODAY**' : "**#{today.schedule_day}-Day**") + " | #{basis}"
        end
      end
    end
  end
end