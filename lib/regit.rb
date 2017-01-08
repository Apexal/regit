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

require_relative 'regit/other/store_data'
require_relative 'regit/server'

module Regit
  extend StoreData

  # CONSTANTS
  GRADES = %w(Freshmen Sophomores Juniors Seniors).freeze

  DEFAULT_ROLES = load_file("#{Dir.pwd}/data/default_roles.yaml")
  DEFAULT_TEXT_CHANNELS = load_file("#{Dir.pwd}/data/default_text_channels.yaml")
  DEFAULT_VOICE_CHANNELS = load_file("#{Dir.pwd}/data/default_voice_channels.yaml")

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

  require_relative 'discordrb/role'
  require_relative 'discordrb/member'
  require_relative 'discordrb/channel'
  require_relative 'discordrb/server'

  BOT = Discordrb::Commands::CommandBot.new(token: CONFIG.discord_token,
                                            client_id: CONFIG.discord_client_id,
                                            prefix: CONFIG.command_prefix,
                                            advanced_functionality: true,
                                            chain_delimiter: '>>',
                                            fancy_log: true)

  Commands.include!
  Events.include!

  at_exit do
    LOGGER.info 'Exiting...'
    save_to_file("#{Dir.pwd}/data/associations.yaml", Regit::CHANNEL_ASSOCIATIONS)
    save_to_file("#{Dir.pwd}/data/verify_codes.yaml", Regit::Registration::VERIFY_CODES)

    exit!
  end
  
  LOGGER.info "Oauth url: #{BOT.invite_url}+&permissions=#{CONFIG.permissions_code}"
  LOGGER.info 'Use [Ctrl+C] to safely stop the bot.'

  avatar = "#{Dir.pwd}/data/Student.jpg"
  
  BOT.run :async
  BOT.profile.avatar = File.open(avatar, 'rb')
  
  run WebApp # Run web app
  
  BOT.sync
end
