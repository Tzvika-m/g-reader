class EbayController < ApplicationController

  def index
    gmail_messages = Gmail::GmailMessages.new(current_user)
    purchases = gmail_messages.get_ebay_purchases

    render json: purchases
  end

end