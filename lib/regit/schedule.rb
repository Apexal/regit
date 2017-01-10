module Regit
  module Schedule
    SCHEDULE = ScheduleSystem.new("#{Dir.pwd}/data/schedule.txt")

    def self.update_work_channel_topic()
      LOGGER.info 'Updating schedule day info...'
      basis = "#{DateTime.now.strftime('%A, %B %e')} | General school discussion, homework help, etc."
      Regit::BOT.servers.each do |id, server|
        work_channel = server.text_channels.find { |t| t.name == 'work' }
        next if work_channel.nil? # Somehow

        today = SCHEDULE.today
        work_channel.topic = (today.nil? ? '**NO SCHOOL TODAY**' : "**#{today.schedule_day}-Day**") + " | #{basis}"
      end
    end
  end
end