require 'json'

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
    if rareflag == 3
      result_hash[:log_string] = "Bought #{data[:definition_id]} (#{data[:total_time]}ms): IF #{data[:rating]} #{data[:preferred_position]} #{name} to price #{data[:bin_price]} at #{data[:expires]} itemid #{data[:item_id]} (#{time_from_start} sec since start)"
    else
      result_hash[:log_string] = "Bought #{data[:definition_id]} (#{data[:total_time]}ms): #{data[:rating]} #{data[:preferred_position]} #{name} to price #{data[:bin_price]} at #{data[:expires]} itemid #{data[:item_id]} (#{time_from_start} sec since start)"
    end

    result_hash[:return_id] = 1
  else
    if rareflag == 3
      result_hash[:log_string] = "Missed #{data[:definition_id]} (#{data[:total_time]}ms): IF #{data[:rating]} #{data[:preferred_position]} #{name} to price #{data[:bin_price]} at #{data[:expires]} (#{time_from_start} sec since start)"
    else
      result_hash[:log_string] = "Missed #{data[:definition_id]} (#{data[:total_time]}ms): #{data[:rating]} #{data[:preferred_position]} #{name} to price #{data[:bin_price]} at #{data[:expires]} (#{time_from_start} sec since start)"
    end

    result_hash[:return_id] = 2
  end

  result_hash
end
