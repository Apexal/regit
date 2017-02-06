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

    # SHOW GROUP INFO
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

    # JOIN GROUP
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


    # LEAVE GROUP
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

    # KICK MEMBER FROM GROUP
    post '/groups/:id/kick' do
      redirect(to('/')) unless @logged_in
      
      group_id = params['id']
      target_username = params['username']
      
      begin
        group = Regit::Database::Group.find(group_id)

        if group.nil?
          session['info'] << 'Invalid group!'
          redirect back
          return
        end

        # Make sure is server owner
        unless @student.member == group.owner
          session['info'] << "You don't own Group #{group.name}!"
          redirect back
          return
        end

        if target_username == @student.username
          session['info'] << 'You can\'t kick yourself!'
          redirect back
          return
        end

        target = Regit::Database::Student.find_by_username(target_username)
        group = Regit::Groups::remove_from_group(target.member, group_id)
        session['info'] << "Kicked #{target.username} from Group '#{group.name}'!"
      rescue => e
        puts e.backtrace.join("\t\n")
        session['info'] << 'Failed to kick member! Please try again later.'
      end
      
      redirect back
    end

    # TRANSFER GROUP OWNERSHIP
    post '/groups/:id/transfer' do
      redirect(to('/')) unless @logged_in
      
      group_id = params['id']
      target_username = params['username']
      
      begin
        group = Regit::Database::Group.find(group_id)

        if group.nil?
          session['info'] << 'Invalid group!'
          redirect back
          return
        end

        # Make sure is server owner
        unless @student.member == group.owner
          session['info'] << "You don't own Group #{group.name}!"
          redirect back
          return
        end

        if target_username == @student.username
          session['info'] << 'You already own the group!'
          redirect back
          return
        end

        target = Regit::Database::Student.find_by_username(target_username)
        if target.nil? || !target.groups.include?(group)
          session['info'] << 'Target doesn\'t exist or is not in the group!'
          redirect back
          return
        end
      
        group.update(owner_username: target_username)
        target.member.pm("You have been given ownership of **Group #{group.name}**!")
        #group.text_channel.send_message("*Ownership of this group has been transferred to #{target.mention}.*")
        session['info'] << "Transfered ownership of Group '#{group.name}' to #{target.username}!"
      rescue => e
        puts e.backtrace.join("\t\n")
        session['info'] << 'Failed to transfer ownership! Please try again later.'
      end
      
      redirect back
    end

    # UPDATE GROUP INFO
    post '/groups/:id/update' do
      redirect(to('/')) unless @logged_in
      
      group_id = params['id']
      new_description = params['description']

      # Validate description
      new_description = new_description.strip[0..254]
      
      if new_description.empty?
        session['info'] << 'No new description given!'
        redirect back
        return
      end

      begin
        group = Regit::Database::Group.find(group_id)

        if group.nil?
          session['info'] << 'Invalid group!'
          redirect back
          return
        end

        # Make sure is server owner
        unless @student.member == group.owner
          session['info'] << "You don't own Group #{group.name}!"
          redirect back
          return
        end
      
        group.update(description: new_description)
        group.text_channel.send_message("*The group's description has been changed to `#{new_description}`.*")
        session['info'] << "Updated description of Group '#{group.name}'!"
      rescue => e
        puts e.backtrace.join("\t\n")
        session['info'] << 'Failed to update description! Please try again later.'
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
