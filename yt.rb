require 'nokogiri'
require 'open-uri'
require 'cgi'
require 'net/http'

p "Fetching HTML page #{ARGV.first}"
html = Nokogiri::HTML(open(ARGV.first.to_s))
f = File.new("yt.html","w+")
f << html.to_s
f.close
js_content = html.at_css("div#watch7-video-container").css("script").last.content
/var\s*swf\s*=\s*\"(?<vars>.*?)\";/ =~ js_content
params = CGI.unescape(vars).split("&")

urls = []

current_url = nil
current_sig = nil

params.each do |param|
	/url=(?<url>.*)/ =~ param
	/sig=(?<sig>.*)/ =~ param
	#p param
	current_url ||= CGI.unescape(CGI.unescape(url)) if url != nil
	current_sig ||= sig
	if !current_url.nil? && !current_sig.nil?
		p "Got URL"
		p "#{CGI.unescape(CGI.unescape(current_url))}&signature=#{current_sig}"
		urls << "#{current_url}&signature=#{current_sig}"
		current_url = nil
		current_sig = nil
	end
end

def fetch(uri, file, limit = 10)
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0
	
	req = Net::HTTP::Get.new(uri.request_uri)
	Net::HTTP.start(uri.host, uri.port) do |http|
		http.request(req) do |resp|
			p resp
			case resp
			when Net::HTTPSuccess then
				begin
					resp.read_body do |seg|
						file.write seg
					end
				end
			when Net::HTTPRedirection then 
				location = resp['location']
				warn "redirected to #{location}"
				fetch(URI(location), limit - 1)
			end
		end
	end
end


urls.each do |url|
	begin
		p url
		uri = URI(url)
		f = File.new('yt.mp4','wb')
		fetch(uri, f)
		print "DONE"
		$stdin.gets
	ensure
		f.close
	end
end
