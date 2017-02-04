module Regit
  module Commands
    # Require all command modules
    Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each { |file| require file }

    @commands = [
      Version,
      WhoIs,
      IrbCommand,
      SetupServer,
      Groups,
      Administration,
      Moderation,
      Studymode,
      Colors,
      Rename,
      Quotes,
      Pin
    ]

    # Include all commands
    def self.include!
      @commands.each do |command|
        Regit::BOT.include!(command)
      end
    end
  end
end