require 'discordrb'
require 'yaml'

require 'bundler/setup'
Bundler.require(:default)

module Regit
  Discordrb::LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
  
  debug = ARGV.include?('-debug') ? :debug : false
  log_streams = [STDOUT]

  if debug
    timestamp = Time.now.strftime(Discordrb::LOG_TIMESTAMP_FORMAT).tr(':', '-')
    log_file = File.new("#{Dir.pwd}/logs/#{timestamp}.log", 'a+')
    log_streams.push(log_file)
  end
  
  LOGGER = Discordrb::LOGGER = Discordrb::Logger.new(nil, log_streams)
  LOGGER.debug = true if debug
  
  require_relative 'regit/other/store_data'
  require_relative 'regit/config'

  # Require all modules
  Dir["#{File.dirname(__FILE__)}/regit/*.rb"].each { |file| require file }

  CONFIG = Config.new
  BOT = Discordrb::Commands::CommandBot.new(token: CONFIG.discord_token,
                                            client_id: CONFIG.discord_client_id,
                                            prefix: CONFIG.command_prefix,
                                            advanced_functionality: false,
                                            fancy_log: true)
  

  Commands.include!
  Events.include!

  at_exit do
    LOGGER.info 'Exiting...'
    
    ServerConfig.save

    exit!
  end
  
  LOGGER.info "Oauth url: #{BOT.invite_url}+&permissions=#{CONFIG.permissions_code}"
  LOGGER.info 'Use ctrl+c to safely stop the bot.'

  BOT.run(:async)
  
  loop do
    sleep 100
  end
end
