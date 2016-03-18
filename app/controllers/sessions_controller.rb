class SessionsController < ApplicationController
  layout false
 
  def new
    puts "started session new"

  end

  def create
    puts "started session create"
    user = User.find_or_create_by_auth(env["omniauth.auth"])
    puts user.inspect
    session[:user_id] = user.id
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end