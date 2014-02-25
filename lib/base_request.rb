require 'uri'

require_relative 'uncompress'

def base_request (http, path, session_headers, method = 'GET', body = ' ')
  base_url = 'https://utas.s2.fut.ea.com'
  uri = URI "#{base_url}#{path}"
  headers = {
    'Accept' => 'application/json',
    'Accept-Charset' => 'UTF-8,*;q=0.5',
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Language' => 'nb,en-US;q=0.8,en;q=0.6',
    'Content-Type' => 'application/json',
    'Host' => 'utas.s2.fut.ea.com',
    'Origin' => 'http://www.easports.com',
    'Referer' => 'http://www.easports.com/iframe/fut/bundles/futweb/web/flash/FifaUltimateTeam.swf',
    'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.186 Safari/535.1',
    'X-UT-Embed-Error' => 'true'
  }

  headers.merge! session_headers
  headers['X-HTTP-Method-Override'] = method

  http.url = uri.to_s
  http.headers = headers
  begin
    http.post_body = body
    http.http_post
  rescue
    sleep 2
  end

  uncompress http.body_str
  # h = uncompress http.body_str
  # unless h[:return] == 0
  #   puts "#{h[:return]} #{h[:string]}"
  #   puts "search_path: #{path}"
  # end

  # h[:string]
end
