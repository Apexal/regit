module Regit
  class Config
    include StoreData

    def initialize
      @path = "#{Dir.pwd}/data/config.yaml"
      puts @path
      temp = load_file(@path)

      @config = temp if temp.is_a?(Hash) && !temp.empty?

      setup_config if @config.nil?
      create_methods
    end
    
    private
      def setup_config
        @config = {}

        puts 'No config file found. Running setup...'
        print 'Discord Token: '
        @config[:discord_token] = gets.chomp

        print 'Discord Client ID: '
        @config[:discord_client_id] = gets.chomp

        print 'Server Owner ID: '
        @config[:server_owner_id] = gets.chomp

        print 'Command Prefix: '
        @config[:command_prefix] = gets.chomp
        @config[:command_prefix] = '!' if @config[:command_prefix].empty?

        print 'Permissions Code: '
        @config[:permissions_code] = gets.chomp


        @config[:db] = {}
        
        print 'Database Name: '
        @config[:db][:database] = gets.chomp

        print 'Database Host: '
        @config[:db][:host] = gets.chomp

        print 'Database Username: '
        @config[:db][:username] = gets.chomp

        print 'Database Password: '
        @config[:db][:password] = gets.chomp

        print 'New Room Name: '
        @config[:new_room_name] = gets.chomp
        
        save
      end

      def create_methods
        @config.keys.each do |key|
          self.class.send(:define_method, key) do
            @config[key]
          end
        end
      end

      def save
        save_to_file(@path, @config)
      end
  end

  # TODO: add way to initialize
end