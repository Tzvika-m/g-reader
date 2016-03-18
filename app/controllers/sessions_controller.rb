class SessionsController < ApplicationController
  layout false
 
  def new
  end

  def create
    user = User.find_or_create_by_auth(env["omniauth.auth"])
    session[:user_id] = user.id
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end