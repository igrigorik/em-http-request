require 'helper'

describe EventMachine::HttpRequest do

  it "should follow redirects on HEAD method (external)" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new('http://www.google.com/').head :redirects => 1
      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        EM.stop
      }
    }
  end

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

  it "should perform a streaming GET" do
    EventMachine.run {

      # digg.com uses chunked encoding
      http = EventMachine::HttpRequest.new('http://digg.com/news').get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        EventMachine.stop
      }
    }
  end

  context "DNS & invalid hosts" do
    xit "should fail GET on DNS timeout" do
      EventMachine.run {
        EventMachine.heartbeat_interval = 0.1
        http = EventMachine::HttpRequest.new('http://127.1.1.1/').get :timeout => 1
        http.callback { failed(http) }
        http.errback {
          http.response_header.status.should == 0
          EventMachine.stop
        }
      }
    end

    xit "should fail GET on invalid host" do
      EventMachine.run {
        EventMachine.heartbeat_interval = 0.1
        http = EventMachine::HttpRequest.new('http://somethinglocal/').get :timeout => 1
        http.callback { failed(http) }
        http.errback {
          http.response_header.status.should == 0
          http.error.should match(/unable to resolve server address/)
          http.uri.to_s.should match('http://somethinglocal:80/')
          EventMachine.stop
        }
      }
    end
  end

  context "keepalive" do
    it "should default to non-keepalive" do
      EventMachine.run {
        headers = {'If-Modified-Since' => 'Thu, 05 Aug 2010 22:54:44 GMT'}
        http = EventMachine::HttpRequest.new('http://www.google.com/images/logos/ps_logo2.png').get :head => headers

        http.errback { fail }
        start = Time.now.to_i
        http.callback {
          (start - Time.now.to_i).should be_within(1).of(0)
          EventMachine.stop
        }
      }
    end

    # https://github.com/tmm1/http_parser.rb/blob/master/ext/ruby_http_parser/ruby_http_parser.c#L304
    xit "should work with keep-alive servers" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://mexicodiario.com/touch.public.json.php').get :keepalive => true

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          EventMachine.stop
        }
      }
    end
  end

end
