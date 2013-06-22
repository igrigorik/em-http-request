$: << 'lib' << '../../lib'

require 'em-http'
require 'em-http/middleware/digest_auth'

digest_config = {
  :username => 'digest_username',
  :password => 'digest_password'
}

EM.run do

  conn_handshake = EM::HttpRequest.new('http://localhost:3000')
  http_handshake = conn_handshake.get

  http_handshake.callback do
    conn = EM::HttpRequest.new('http://localhost:3000')
    conn.use EM::Middleware::DigestAuth, http_handshake.response_header['WWW_AUTHENTICATE'], digest_config
    http = conn.get
    http.callback do
      puts http.response
      EM.stop
    end
  end
end
