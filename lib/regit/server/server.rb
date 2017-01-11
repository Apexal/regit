require 'sinatra/base'
require 'omniauth-discord'

module Regit
  class WebApp < Sinatra::Base
    set :bind, '45.55.205.134'

    use Rack::Session::Cookie
    
    use OmniAuth::Builder do
      provider :discord, Regit::CONFIG.discord_client_id, Regit::CONFIG.discord_client_secret
    end

    get '*' do
      session['info'] ||= []
      session['logged_in'] ||= false

      @student = Regit::Database::Student.find_by_discord_id(session['discord_id'])

      @logged_in = session['logged_in']

      @info = session['info']
      session['info'] = []
      pass
    end

    get '/' do
      'Hello world'
    end

    get '/auth/discord/callback' do
      binding.pry
      session['discord_id'] = request.env['omniauth.auth'].uid
      session['discord_verified'] = request.env['omniauth.auth'].extra.raw_info.verified
    end

    get '/auth/failure' do
      'Maybe next time'
    end
  end
end