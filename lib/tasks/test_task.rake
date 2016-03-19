require 'pp'
require 'base64'
require 'rubygems'
require 'nokogiri'
require 'cgi'

task :check_inbox => :environment do
	@user = User.first
	puts @user.fresh_token
  client = Google::APIClient.new
  client.authorization.access_token = @user.fresh_token
  service = client.discovered_api('gmail')
  result = client.execute(
    :api_method => service.users.messages.list,
    :parameters => {'userId' => 'me', 'labelIds' => ['INBOX'], 'q' => 'from: ebay@ebay.com "your order"'},
    :headers => {'Content-Type' => 'application/json'})
  messages = JSON.parse(result.body)['messages'] || []
  messages.each do |msg|
	  get_details(msg['id'])
	end
	
	puts messages.count
end

task :read_files => :environment do
	items = {}
	@count = 0
	path = 'C:\Sites\g-reader\fold'
	Dir.foreach(path) do |item|
  	next if item == '.' or item == '..'  	
  	mail = handle_file(path + '\\' + item)
  	next unless mail
  	if !items.keys.include?(mail[:id])
  		items[mail[:id]] = mail[:data]
  	else
  		items[mail[:id]][:name] ||= mail[:data][:name]
  		items[mail[:id]][:price] ||= mail[:data][:price]
  		items[mail[:id]][:seller] ||= mail[:data][:seller]
			items[mail[:id]][:date] << mail[:data][:date]
  	end
	end

end

def handle_file(path)
	price_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(3)'
	price_css2 = 'body > table:nth-child(3)'
	product_name_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(3) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)'
	product_name_css2 = '#titleComponent > div:nth-child(1) > p:nth-child(1)'
	product_name_css3 = 'h2.product-name > a:nth-child(1)'
	date_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1)'
	seller_css = 'body > table:nth-child(9) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > table:nth-child(1) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1) > b:nth-child(1) > a:nth-child(2)'
	return_val = nil

	file = File.open(path, "r")
	contents = file.read

	html_doc = Nokogiri::HTML(contents)

	id = get_item_id(html_doc)

	

	if id != []
		@count += 1
		product_name = html_doc.css(product_name_css).text.strip.first(40)
		product_name = html_doc.css(product_name_css2).text.strip.first(40) if product_name == ""
		product_name = html_doc.css(product_name_css3).text.strip.first(40) if product_name == ""

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
				price: html_doc.css(price_css).text.strip,
				seller: html_doc.css(seller_css).text.strip
			}
		}
	end

	return_val
end

def get_item_id(html_doc)
	href = nil
	html_doc.search('a').each do |link|
		if link['href'].include?('item')
			href = link['href'].downcase
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

def get_details(id)
  client = Google::APIClient.new
  client.authorization.access_token = @user.fresh_token
  service = client.discovered_api('gmail')
  result = client.execute(
    :api_method => service.users.messages.get,
    :parameters => {'userId' => 'me', 'id' => id},
    :headers => {'Content-Type' => 'application/json'})
  data = JSON.parse(result.body)
  byebug
  out_file = File.new(id.to_s + ".html", "w")
	if data['payload']['parts'][0]['mimeType'] == "text/html"
		out_file.puts(Base64.urlsafe_decode64(data['payload']['parts'][0]['body']['data']).force_encoding("utf-8"))
	else
		out_file.puts(Base64.urlsafe_decode64(data['payload']['parts'][1]['body']['data']).force_encoding("utf-8"))
	end
	out_file.close
end





