require 'base64'
require 'rubygems'
require 'nokogiri'
require 'cgi'

module Gmail
  class GmailMessages

    def initialize(user)
      @user = user
    end

    def get_ebay_purchases
    	@result = {}
		  client = Google::APIClient.new
		  client.authorization.access_token = @user.fresh_token
		  service = client.discovered_api('gmail')
		  response = client.execute(
		    :api_method => service.users.messages.list,
		    :parameters => {'userId' => 'me', 'labelIds' => ['INBOX'], 'q' => 'from: ebay@ebay.com "your order"'},
		    :headers => {'Content-Type' => 'application/json'})
		  messages = JSON.parse(response.body)['messages'] || []
		  messages.each do |msg|
			  handle_message(msg['id'])
			end

			return @result
    end

    def handle_message(id)
  	  client = Google::APIClient.new
		  client.authorization.access_token = @user.fresh_token
		  service = client.discovered_api('gmail')
		  response = client.execute(
		    :api_method => service.users.messages.get,
		    :parameters => {'userId' => 'me', 'id' => id},
		    :headers => {'Content-Type' => 'application/json'})
		  data = JSON.parse(response.body)
		  
			if data['payload']['parts'][0]['mimeType'] == "text/html"
				content = Base64.urlsafe_decode64(data['payload']['parts'][0]['body']['data']).force_encoding("utf-8")
			else
				content = Base64.urlsafe_decode64(data['payload']['parts'][1]['body']['data']).force_encoding("utf-8")
			end

			extracted_data = data_from_document(content)

			if extracted_data
				if !@result.keys.include?(extracted_data[:id])
		  		@result[extracted_data[:id]] = extracted_data[:data]
		  	else
		  		@result[extracted_data[:id]][:name] ||= extracted_data[:data][:name]
		  		@result[extracted_data[:id]][:price] ||= extracted_data[:data][:price]
		  		@result[extracted_data[:id]][:seller] ||= extracted_data[:data][:seller]
					@result[extracted_data[:id]][:date] << extracted_data[:data][:date]
		  	end
			end
    end

    def get_item_id(html_doc)
			href = nil
			html_doc.search('a').each do |item|
				link = item['href'].downcase
				if link.include?('item')
					href = link
					break
				end
			end
			return nil if !href
			link_params = CGI::parse(URI.decode(href))
			if link_params['itemid'].empty?
				link_params['item']
			else
				link_params['itemid']
			end
		end

		def data_from_document(content)
			price_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(3)'
			price_css2 = 'body > table:nth-child(3)'
			product_name_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(3) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)'
			product_name_css2 = '#titleComponent > div:nth-child(1) > p:nth-child(1)'
			product_name_css3 = 'h2.product-name > a:nth-child(1)'
			date_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1)'
			seller_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > b:nth-child(1) > a:nth-child(2)'

			html_doc = Nokogiri::HTML(content)
			return_val = nil
			
			id = get_item_id(html_doc)

			if id != []
				product_name = html_doc.css(product_name_css).text.strip
				product_name = html_doc.css(product_name_css2).text.strip if product_name == ""
				product_name = html_doc.css(product_name_css3).text.strip if product_name == ""

				product_price = html_doc.css(price_css).text.strip
				if product_price == ""
					price_text = html_doc.css(price_css2).text.strip.downcase
					product_price = price_text.split('paid : ')[1].split(' with')[0] if price_text and price_text.include?('paid') #######
				end

				return_val = {
				 	id: id,
				 	data: {
						date: [html_doc.css(date_css).text.strip.to_date],
						name: product_name,
						price: product_price,
						seller: html_doc.css(seller_css).text.strip
					}
				}
			end
			return_val
		end



	end
end