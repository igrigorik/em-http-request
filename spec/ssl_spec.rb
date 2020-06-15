require 'helper'

requires_connection do

  describe EventMachine::HttpRequest do
    it "should initiate SSL/TLS on HTTPS connections" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('https://mail.google.com:443/mail/').get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 302
          EventMachine.stop
        }
      }
    end

    describe "TLS hostname verification" do
      before do
        @cve_warning = "[WARNING; em-http-request] TLS hostname validation is disabled (use 'tls: {verify_peer: true}'), see" +
                       " CVE-2020-13482 and https://github.com/igrigorik/em-http-request/issues/339 for details"
        @orig_stderr = $stderr
        $stderr = StringIO.new
      end

      after do
        $stderr = @orig_stderr
      end

      it "should not warn if verify_peer is specified" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('https://mail.google.com:443/mail', {tls: {verify_peer: false}}).get

          http.callback {
            $stderr.rewind
            $stderr.string.chomp.should_not eq(@cve_warning)

            EventMachine.stop
          }
        }
      end

      it "should not warn if verify_peer is true" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('https://mail.google.com:443/mail', {tls: {verify_peer: true}}).get

          http.callback {
            $stderr.rewind
            $stderr.string.chomp.should_not eq(@cve_warning)

            EventMachine.stop
          }
        }
      end

      it "should warn if verify_peer is unspecified" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('https://mail.google.com:443/mail').get

          http.callback {
            $stderr.rewind
            $stderr.string.chomp.should eq(@cve_warning)

            EventMachine.stop
          }
        }
      end
    end
  end

end
