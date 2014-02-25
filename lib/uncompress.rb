require 'zlib'
require 'stringio'

def uncompress string
begin
  Zlib::GzipReader.new(StringIO.new(string)).read
rescue
  string
end
end
