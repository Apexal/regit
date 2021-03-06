DATE_FORMAT = '%Y-%m-%d'.freeze

module Regit
  module Commands
    module SchoolCommand
      extend Discordrb::Commands::CommandContainer

      command(:preach, permission_level: 3) do |event|
        
      end

      command(:school, min_args: 0, max_args: 0, description: 'Show school info.', permission_level: 1) do |event|
        lines = []
        lines << '__**:school: School Info :school_satchel:**__'

        now = Date.parse(Time.now.to_s)
        today = now.strftime(DATE_FORMAT)

        'Coming soon!'
      end
    end
  end
end