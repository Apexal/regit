require 'sinatra/base'
require 'omniauth-discord'

module Regit
  class WebApp < Sinatra::Base
    set :bind, '45.55.205.134'

    use Rack::Session::Cookie
    
    use OmniAuth::Builder do
      provider :discord, Regit::CONFIG.discord_client_id, Regit::CONFIG.discord_client_secret
    end

    before do
      session['info'] ||= []

      @student = Regit::Database::Student.find_by_discord_id(session['discord_id']) unless session['discord_id'].nil?
      @logged_in = !@student.nil?
      @info = session['info']

      session['info'] = []
    end

    get '/' do
      erb :index, layout: :layout
    end
    
    get '/users' do
      redirect(to('/')) unless @logged_in
      
      @title = 'Users'
      @users = @student.school.members
      
      erb :users, layout: :layout
    end
    
    get '/users/:username' do
      redirect(to('/')) unless @logged_in

      username = params['username']
      @user = Regit::Database::Student.find_by_username(username)

      if @user.nil?
        session['info'] << 'Invalid username!'
        redirect back
        return
      end

      @title = "#{@user.first_name} #{@user.last_name}"

      erb :user, layout: :layout
    end

    get '/groups' do
      redirect(to('/')) unless @logged_in
      
      @title = 'Groups'

      @groups = @student.school.groups
      erb :groups, layout: :layout
    end

    get '/groups/:id' do
      redirect(to('/')) unless @logged_in

      group_id = params['id']
      @group = Regit::Database::Group.find(group_id)

      if @group.nil?
        session['info'] << 'That group doesn\'t exist!'
        redirect back
        return
      end

      @title = "Group #{@group.name}"

      erb :group, layout: :layout
    end

    post '/groups/:id/join' do
      redirect(to('/')) unless @logged_in

      group_id = params['id']
      
      begin
        group = Regit::Groups::add_to_group(@student.member, group_id)
        session['info'] << "Joined group '#{group.name}'!"
      rescue => e
        puts e
        puts e.backtrace.join("\t\n")
        session['info'] << 'Failed to join group! Please try again later.'
      end
      
      redirect back
    end

    post '/groups/:id/leave' do
      redirect(to('/')) unless @logged_in
      
      group_id = params['id']
      begin
        group = Regit::Groups::remove_from_group(@student.member, group_id)
        session['info'] << "Left group '#{group.name}'!"
      rescue => e
        puts e.backtrace.join("\t\n")
        session['info'] << 'Failed to leave group! Please try again later.'
      end
      
      redirect back
    end

    get '/auth/discord/callback' do
      session['discord_id'] = request.env['omniauth.auth'].uid
      session['discord_verified'] = request.env['omniauth.auth'].extra.raw_info.verified
      redirect(to('/'))
    end

    get '/logout' do
      session['discord_id'] = nil
      session['discord_verified'] = nil
      session['info'] << 'You have logged out.'
      redirect back
    end

    get '/auth/failure' do
      'Maybe next time'
    end
  end
end
