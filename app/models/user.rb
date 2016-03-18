require 'net/http'
require 'json'

class User < ActiveRecord::Base
	def self.find_or_create_by_auth(auth)
  	user = User.where(uid: auth.uid).first_or_create
  	user.update(
  		uid: auth.uid,
  		name: auth.info.name,
  		access_token: auth.credentials.token,
  		refresh_token: auth.credentials.refresh_token,
  		token_expires_at:	Time.at(auth.credentials.expires_at)
  	)
  	user
  end


  def to_params
    {
    'refresh_token' => refresh_token,
    'client_id' => ENV['GOOGLE_CLIENT_ID'], # Rails.application.secrets.google_client_id,
    'client_secret' => ENV['GOOGLE_CLIENT_SECRET'], # Rails.application.secrets.google_client_secret,
    'grant_type' => 'refresh_token'
		}
  end
 
  def request_token_from_google
    url = URI("https://accounts.google.com/o/oauth2/token")
    Net::HTTP.post_form(url, self.to_params)
  end
 
  def refresh!
    response = request_token_from_google
    data = JSON.parse(response.body)
    update_attributes(
	    access_token: data['access_token'],
	    token_expires_at: Time.now + (data['expires_in'].to_i).seconds
	  )
  end
 
  def expired?
    token_expires_at < Time.now
  end
 
  def fresh_token
    refresh! if expired?
    access_token
  end
end
