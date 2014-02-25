#!/usr/bin/env ruby

require 'curb'
require 'json'

require_relative 'lib/base_request'
require_relative 'lib/get_description'

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

    request = base_request(http, search_path, session_headers)

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
