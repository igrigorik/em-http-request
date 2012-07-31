require 'webrick'

include WEBrick

config = { :Realm => 'DigestAuth_REALM' }

htdigest = WEBrick::HTTPAuth::Htdigest.new 'my_password_file'
htdigest.set_passwd config[:Realm], 'digest_username', 'digest_password'
htdigest.flush

config[:UserDB] = htdigest

digest_auth = WEBrick::HTTPAuth::DigestAuth.new config

class TestServlet < HTTPServlet::AbstractServlet
  def do_GET(req, res)
    @options[0][:authenticator].authenticate req, res
    res.body = "You are authenticated to see the super secret data\n"
  end
end

s = HTTPServer.new(:Port => 3000)
s.mount('/', TestServlet, {:authenticator => digest_auth})
trap("INT") do
  File.delete('my_password_file')
  s.shutdown
end
s.start
