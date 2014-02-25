require 'net/http'
require 'uri'

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
