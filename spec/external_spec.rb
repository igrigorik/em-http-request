require 'helper'

requires_connection do

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

    it "should follow redirect to https and initiate the handshake" do
      EventMachine.run {
        http = EventMachine::HttpRequest.new('http://github.com/').get :redirects => 5

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          EventMachine.stop
        }
      }
    end

    it "should perform a streaming GET" do
      EventMachine.run {

        # digg.com uses chunked encoding
        http = EventMachine::HttpRequest.new('http://www.httpwatch.com/httpgallery/chunked/').get

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          EventMachine.stop
        }
      }
    end

    it "should handle a 100 continue" do
      EventMachine.run {
        # 8.2.3 Use of the 100 (Continue) Status - http://www.ietf.org/rfc/rfc2616.txt
        #
        # An origin server SHOULD NOT send a 100 (Continue) response if
        # the request message does not include an Expect request-header
        # field with the "100-continue" expectation, and MUST NOT send a
        # 100 (Continue) response if such a request comes from an HTTP/1.0
        # (or earlier) client. There is an exception to this rule: for
        # compatibility with RFC 2068, a server MAY send a 100 (Continue)
        # status in response to an HTTP/1.1 PUT or POST request that does
        # not include an Expect request-header field with the "100-
        # continue" expectation. This exception, the purpose of which is
        # to minimize any client processing delays associated with an
        # undeclared wait for 100 (Continue) status, applies only to
        # HTTP/1.1 requests, and not to requests with any other HTTP-
        # version value.
        #
        # 10.1.1: 100 Continue - http://www.ietf.org/rfc/rfc2068.txt
        # The client may continue with its request. This interim response is
        # used to inform the client that the initial part of the request has
        # been received and has not yet been rejected by the server. The client
        # SHOULD continue by sending the remainder of the request or, if the
        # request has already been completed, ignore this response. The server
        # MUST send a final response after the request has been completed.

        url = 'http://ws.serviceobjects.com/lv/LeadValidation.asmx/ValidateLead_V2'
        http = EventMachine::HttpRequest.new(url).post :body => {:name => :test}

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 500
          http.response.should match('Missing')
          EventMachine.stop
        }
      }
    end

    it "should detect deflate encoding" do
      pending "need an endpoint which supports deflate.. MSN is no longer"
      EventMachine.run {

        options = {:head => {"accept-encoding" => "deflate"}, :redirects => 5}
        http = EventMachine::HttpRequest.new('http://www.msn.com').get options

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response_header["CONTENT_ENCODING"].should == "deflate"

          EventMachine.stop
        }
      }
    end

    it "should stream chunked gzipped data" do
      EventMachine.run {
        options = {:head => {"accept-encoding" => "gzip"}}
        # GitHub sends chunked gzip, time for a little Inception ;)
        http = EventMachine::HttpRequest.new('https://github.com/igrigorik/em-http-request/commits/master').get options

        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 200
          http.response_header["CONTENT_ENCODING"].should == "gzip"
          http.response.should == ''

          EventMachine.stop
        }

        body = ''
        http.stream do |chunk|
          body << chunk
        end
      }
    end

    context "keepalive" do
      it "should default to non-keepalive" do
        EventMachine.run {
          headers = {'If-Modified-Since' => 'Thu, 05 Aug 2010 22:54:44 GMT'}
          http = EventMachine::HttpRequest.new('http://www.google.com/images/logos/ps_logo2.png').get :head => headers

          http.errback { fail }
          start = Time.now.to_i
          http.callback {
            (Time.now.to_i - start).should be_within(2).of(0)
            EventMachine.stop
          }
        }
      end

      it "should work with keep-alive servers" do
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
end
