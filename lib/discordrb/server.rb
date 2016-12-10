module Discordrb
  
  class Server
    attr_reader :config
    attr_reader :school

    old_initialize = instance_method(:initialize)
    define_method(:initialize) do |data, bot, exists = true|
      old_initialize.bind(self).call(data, bot, exists)
      @config = Regit::ServerConfig.load_config(@id)

      @school = Regit::Database::School.find_by_server_id(@id)
      if @school.nil?
        LOGGER.info 'Adding school to Database'
        @school = Regit::Database::School.create(title: 'School', school_type: 'High School', server_id: @id)
      end
      LOGGER.info @school.title

      create_methods
    end

    def update_config(attributes = {})
      @config.merge!(attributes) if attributes.is_a?(Hash)
      Regit::ServerConfig.update_servers(@config, @id)
    end

    def table
      Terminal::Table.new(headings: %w(Description Value Command)) do |t|
        @config.each do |key, value|
          setting_info = Regit::ServerConfig.settings_info[key]
          description = setting_info[:description]
          value = bool_to_words(value) if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          command = "#{setting_info[:command]} #{setting_info[:setting]}"

          t.add_row([description, value, command])
        end
      end
    end

    private

    def create_methods
      @config.keys.each do |key|
        self.class.send(:define_method, key) do
          @config[key]
        end
      end
    end
  end
end
