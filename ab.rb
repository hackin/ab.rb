#!/usr/bin/env ruby

require 'curb'
require 'json'
require 'logger'
require 'net/http'
require 'uri'
require 'zlib'

def uncompress string
  begin
    Zlib::GzipReader.new(StringIO.new(string), :external_encoding => string.encoding).read
  rescue
    string
  end
end

def get_description asset_id
  asset_uri = URI.parse "http://cdn.content.easports.com/fifa/fltOnlineAssets/C74DDF38-0B11-49b0-B199-2E2A11D1CC13/2014/fut/items/web/#{asset_id}.json"
  asset_http = Net::HTTP.new(asset_uri.host, asset_uri.port)
  asset_request = Net::HTTP::Get.new(asset_uri.request_uri)
  asset_response = asset_http.request(asset_request)

  doc = JSON.parse asset_response.body

  if doc['Item']['CommonName']
    doc['Item']['CommonName']
  else
    doc['Item']['FirstName'] + " " + doc['Item']['LastName']
  end
end

def parse_bid (response, data, name)
  result = JSON.parse response
  rareflag = data[:rareflag].to_i

  # List of return codes for return_hash
  # 1 - Sucessfully bought card
  # 2 - Missed card
  result_hash = { :log_string => "", :return_id => 0 }

  profit = data[:discard_value].to_i - data[:bin_price].to_i
  time_from_start = (data[:timestamp].to_i - data[:start_time].to_i) / 1000

  if result.has_key?('credits') && result.has_key?('auctionInfo')
    result_hash[:log_string] = "Bought (#{data[:total_time]} ms): #{data[:rating]} #{data[:preferred_position]} #{name} to price #{data[:bin_price]} at #{data[:expires]} itemid #{data[:item_id]} (#{time_from_start} sec since start)"
    result_hash[:return_id] = 1
  else
    result_hash[:log_string] = "Missed (#{data[:total_time]} ms): #{data[:rating]} #{data[:preferred_position]} #{name} to price #{data[:bin_price]} at #{data[:expires]} (#{time_from_start} sec since start)"
    result_hash[:return_id] = 2
  end

  result_hash
end

def base_request (http, path, session_headers, method, body = " ")
  headers = {
    'Accept' => 'application/json',
    'Accept-Charset' => 'UTF-8,*;q=0.5',
    'Accept-Encoding' => 'Accept-Encoding: gzip,deflate',
    'Accept-Language' => 'nb,en-US;q=0.8,en;q=0.6',
    'Host' => 'utas.s2.fut.ea.com',
    'Origin' => 'http://www.easports.com',
    'Referer' => 'http://www.easports.com/iframe/fut/bundles/futweb/web/flash/FifaUltimateTeam.swf',
    'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.186 Safari/535.1',
    'X-UT-Embed-Error' => 'true'
  }

  base_url = 'https://utas.s2.fut.ea.com'
  uri = URI "#{base_url}#{path}"

  headers.merge! session_headers
  headers['X-HTTP-Method-Override'] = method
  headers['Content-Type'] = 'application/json' if method == 'POST' or method == 'PUT'

  http.url = uri.to_s
  http.headers = headers
  begin
    http.post_body = body
    http.http_post
  rescue
    sleep 2
  end

  uncompress http.body_str
end

def list_item (http, session_header, item_id, start_price, bid_price)
  body_string = "{\"itemData\":[{\"pile\":\"trade\",\"id\":\"#{item_id}\"}]}"
  item_request = base_request(http, '/ut/game/fifa14/item', session_header, 'PUT', body_string)

  body_string = "{\"duration\":3600,\"itemData\":{\"id\":#{item_id}},\"startingBid\":#{start_price},\"buyNowPrice\":#{bid_price}}"
  auction_request = base_request(http, '/ut/game/fifa14/auctionhouse', session_header, 'POST', body_string)

  items_request = base_request(http, '/ut/game/fifa14/purchased/items', session_header, 'GET')

  credit_request = base_request(http, '/ut/game/fifa14/user/credits', session_header, 'GET')
end

start_time = (Time.now.to_f * 1000.0).to_i

players = JSON.parse IO.read 'players.json'
session_headers = JSON.parse IO.read 'session.json'

http = Curl::Easy.new
auction_regexp = Regexp.new('auctionInfo\":\[\{').freeze

loop do
  players.shuffle.each do |player|
    search_path = "/ut/game/fifa14/transfermarket?type=player&num=16&start=0&lev=gold"

    search_path << "&leag=#{player['leag']}" if player.has_key? 'leag'
    search_path << "&definitionId=#{player['defid']}" if player.has_key? 'defid'
    search_path << "&maskedDefId=#{player['mdefid']}" if player.has_key? 'mdefid'
    search_path << "&nat=#{player['nat']}"   if player.has_key? 'nat'
    search_path << "&team=#{player['team']}" if player.has_key? 'team'
    search_path << "&zone=#{player['zone']}" if player.has_key? 'zone'
    search_path << "&minb=#{player['minb']}" if player.has_key? 'minb'
    search_path << "&pos=#{player['pos']}"   if player.has_key? 'pos'

    if player.has_key? 'maxb'
      if player['maxb'].is_a? Array
        search_path << "&maxb=#{player['maxb'].sample}"
      else
        search_path << "&maxb=#{player['maxb']}"
      end
    end

    sleep rand(0.05..0.10)

    request = base_request(http, search_path, session_headers, 'GET')

    if /auctionInfo\":\[\{/ =~ request
      result = {}
      result[:trade_id] = request[/\"tradeId\":(\d+)/, 1].to_s
      result[:bin_price] = request[/\"buyNowPrice\":(\d+)/, 1].to_s

      bid = base_request(http, "/ut/game/fifa14/trade/#{result[:trade_id]}/bid", session_headers, 'PUT', "{\"bid\":#{result[:bin_price]}}")
      total_time = (http.total_time * 1000.0).to_i
      timestamp = (Time.now.to_f * 1000.0).to_i

      credit_request = base_request(http, '/ut/game/fifa14/user/credits', session_headers, 'GET')

      result[:resource_id] = request[/\"resourceId\":(\d+)/, 1]
      result[:asset_id] = request[/\"assetId\":(\d+)/, 1]
      name = get_description result[:asset_id]

      result[:expires] = request[/\"expires\":(\d+)/, 1]
      result[:rareflag] = request[/\"rareflag\":(\d+)/, 1]
      result[:item_id] = request[/\"id\":(\d+)/, 1]
      result[:discard_value] = request[/\"discardValue\":(\d+)/, 1]
      result[:rating] = request[/\"rating\":(\d+)/, 1]
      result[:preferred_position] = request[/\"preferredPosition\":\"(\w+)\"/, 1]
      result[:total_time] = total_time
      result[:start_time] = start_time
      result[:timestamp] = timestamp

      parsed_output = parse_bid(bid, result, name)

      case parsed_output[:return_id]
      when 1
        puts "#{Time.now.to_i}: #{parsed_output[:log_string]}"
      when 2
        puts "#{Time.now.to_i}: #{parsed_output[:log_string]}"
        sleep 8
      end
    else
      unless request[/\"auctionInfo\":\[\]/]
        sleep 8
      end
    end

    sleep rand(0.05..0.15)
  end
end