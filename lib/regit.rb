require 'rubygems'

require 'yaml'
require 'irb'
require 'pry'

require 'bundler/setup'
Bundler.setup(:default)

require 'discordrb'
require 'mysql2'
require 'active_record'
require 'sinatra'

# Global methods
module Kernel
  
end

require_relative 'regit/other/store_data'
module Regit
  extend StoreData

  # CONSTANTS
  GRADES = %w(Freshmen Sophomores Juniors Seniors).freeze

  Discordrb::LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
  
  debug = ARGV.include?('--debug') ? :debug : false
  log_streams = [STDOUT]

  if debug
    timestamp = Time.now.strftime(Discordrb::LOG_TIMESTAMP_FORMAT).tr(':', '-')
    log_file = File.new("#{Dir.pwd}/logs/#{timestamp}.log", 'a+')
    log_streams.push(log_file)
  end
  
  LOGGER = Discordrb::LOGGER = Discordrb::Logger.new(nil, log_streams)
  LOGGER.debug = true if debug
  
  require_relative 'regit/config'
  
  CONFIG = Config.new
  
  OLD_VOICE_STATES = {}
  CHANNEL_ASSOCIATIONS = {}
  
  # Require all modules
  Dir["#{File.dirname(__FILE__)}/regit/*.rb"].each { |file| require file }

  require_relative 'discordrb/member'
  require_relative 'discordrb/channel'
  require_relative 'discordrb/server'

  BOT = Discordrb::Commands::CommandBot.new(token: CONFIG.discord_token,
                                            client_id: CONFIG.discord_client_id,
                                            prefix: CONFIG.command_prefix,
                                            advanced_functionality: true,
                                            fancy_log: true)

  Commands.include!
  Events.include!

  at_exit do
    LOGGER.info 'Exiting...'
    save_to_file("#{Dir.pwd}/data/associations.yaml", Regit::CHANNEL_ASSOCIATIONS)
    exit!
  end
  
  LOGGER.info "Oauth url: #{BOT.invite_url}+&permissions=#{CONFIG.permissions_code}"
  LOGGER.info 'Use ctrl+c to safely stop the bot.'

  avatar = "#{Dir.pwd}/data/Student.jpg"
  
  BOT.run :async
  BOT.profile.avatar = File.open(avatar, 'rb')
  
  #WebApp.run! # Run web app
  
  BOT.sync
end
