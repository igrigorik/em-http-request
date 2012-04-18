require 'eventmachine'
begin
require 'em-socksify'
rescue LoadError
	# Only need this if using SOCKS
end
require 'addressable/uri'
require 'http/parser'

require 'base64'
require 'socket'

require 'em-http/core_ext/bytesize'
require 'em-http/http_connection'
require 'em-http/http_header'
require 'em-http/http_encoding'
require 'em-http/http_status_codes'
require 'em-http/http_client_options'
require 'em-http/http_connection_options'
require 'em-http/client'
require 'em-http/multi'
require 'em-http/request'
require 'em-http/decoders'
