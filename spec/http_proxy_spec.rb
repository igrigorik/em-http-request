require 'helper'

shared_examples "*_PROXY var (through proxy)" do
  it "should use HTTP proxy" do
    EventMachine.run {
      http = EventMachine::HttpRequest.new("#{proxy_test_scheme}://127.0.0.1:8090/?q=test").get

      http.errback { failed(http) }
      http.callback {
        http.response_header.status.should == 200
        http.response_header.should_not include("X_PROXY_AUTH")
        http.response.should match('test')
        EventMachine.stop
      }
    }
  end
end

shared_examples "*_PROXY var (testing var)" do
  subject { HttpConnectionOptions.new("#{proxy_test_scheme}://example.com", {}) }
  it { expect(subject.proxy_from_env).to eq({ :host => "127.0.0.1", :port => 8083, :type => :http }) }
  it { expect(subject.host).to eq "127.0.0.1" }
  it { expect(subject.port).to be 8083 }
  it do
    case proxy_test_scheme.to_sym
    when :http
      expect(subject.http_proxy?).to be_truthy
    when :https
      expect(subject.connect_proxy?).to be_truthy
    end
  end
end

describe EventMachine::HttpRequest do

  context "connections via" do
    context "without *_PROXY env" do
      let(:proxy) { {:proxy => { :host => '127.0.0.1', :port => 8083 }} }
      let(:authenticated_proxy) { {:proxy => { :host => '127.0.0.1', :port => 8083, :authorization => ["user", "name"] } } }

      it "should use HTTP proxy" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/?q=test', proxy).get

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.response_header.should_not include("X_PROXY_AUTH")
            http.response.should match('test')
            EventMachine.stop
          }
        }
      end

      it "should use HTTP proxy with authentication" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/proxyauth?q=test', authenticated_proxy).get

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.response_header['X_PROXY_AUTH'].should == "Proxy-Authorization: Basic dXNlcjpuYW1l"
            http.response.should match('test')
            EventMachine.stop
          }
        }
      end

      it "should send absolute URIs to the proxy server" do
        EventMachine.run {

          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/?q=test', proxy).get

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200

            # The test proxy server gives the requested uri back in this header
            http.response_header['X_THE_REQUESTED_URI'].should == 'http://127.0.0.1:8090/?q=test'
            http.response_header['X_THE_REQUESTED_URI'].should_not == '/?q=test'
            http.response.should match('test')
            EventMachine.stop
          }
        }
      end

      it "should strip basic auth from before the host in URI sent to proxy" do
        EventMachine.run {

          http = EventMachine::HttpRequest.new('http://user:pass@127.0.0.1:8090/echo_authorization_header', proxy).get

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            # The test proxy server gives the requested uri back in this header
            http.response_header['X_THE_REQUESTED_URI'].should == 'http://127.0.0.1:8090/echo_authorization_header'
            # Ensure the basic auth was converted to a header correctly
            http.response.should match('authorization:Basic dXNlcjpwYXNz')
            EventMachine.stop
          }
        }
      end

      it "should include query parameters specified in the options" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/', proxy).get :query => { 'q' => 'test' }

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200
            http.response.should match('test')
            EventMachine.stop
          }
        }
      end

      it "should use HTTP proxy while redirecting" do
        EventMachine.run {
          http = EventMachine::HttpRequest.new('http://127.0.0.1:8090/redirect', proxy).get :redirects => 1

          http.errback { failed(http) }
          http.callback {
            http.response_header.status.should == 200

            http.response_header['X_THE_REQUESTED_URI'].should == 'http://127.0.0.1:8090/gzip'
            http.response_header['X_THE_REQUESTED_URI'].should_not == '/redirect'

            http.response_header["CONTENT_ENCODING"].should == "gzip"
            http.response.should == "compressed"
            http.last_effective_url.to_s.should == 'http://127.0.0.1:8090/gzip'
            http.redirects.should == 1

            EventMachine.stop
          }
        }
      end
    end

    context "when parsing *_PROXY var (through proxy)s" do
      context "with $HTTP_PROXY env" do
        let(:proxy_test_scheme) { :http }

        before(:all) do
          PROXY_ENV_VARS.each {|k| ENV.delete k }
          ENV['HTTP_PROXY'] = 'http://127.0.0.1:8083'
        end

        include_examples "*_PROXY var (through proxy)"
      end

      context "with $http_proxy env" do
        let(:proxy_test_scheme) { :http }

        before(:all) do
          PROXY_ENV_VARS.each {|k| ENV.delete k }
          ENV['http_proxy'] = 'http://127.0.0.1:8083'
        end

        include_examples "*_PROXY var (through proxy)"
      end

      ## TODO: Use a Mongrel HTTP server that can handle SSL:
      context "with $HTTPS_PROXY env", skip: "Mongrel isn't configured to handle HTTPS, currently" do
        let(:proxy_test_scheme) { :https }

        before(:all) do
          PROXY_ENV_VARS.each {|k| ENV.delete k }
          ENV['HTTPS_PROXY'] = 'http://127.0.0.1:8083'
        end

        include_examples "*_PROXY var (through proxy)"
      end

      ## TODO: Use a Mongrel HTTP server that can handle SSL:
      context "with $https_proxy env", skip: "Mongrel isn't configured to handle HTTPS, currently" do
        let(:proxy_test_scheme) { :https }

        before(:all) do
          PROXY_ENV_VARS.each {|k| ENV.delete k }
          ENV['https_proxy'] = 'http://127.0.0.1:8083'
        end

        include_examples "*_PROXY var (through proxy)"
      end

      context "with $ALL_PROXY env" do
        let(:proxy_test_scheme) { :http }

        before(:all) do
          PROXY_ENV_VARS.each {|k| ENV.delete k }
          ENV['ALL_PROXY'] = 'http://127.0.0.1:8083'
        end

        include_examples "*_PROXY var (through proxy)"
      end
    end
  end

  context "when parsing *_PROXY vars" do
    context "without a *_PROXY var" do
      before(:all) do
        PROXY_ENV_VARS.each {|k| ENV.delete k }
      end

      subject { HttpConnectionOptions.new("http://example.com", {}) }
      it { expect(subject.proxy_from_env).to be_nil }
      it { expect(subject.host).to eq "example.com" }
      it { expect(subject.port).to be 80 }
      it { expect(subject.http_proxy?).to be_falsey }
      it { expect(subject.connect_proxy?).to be_falsey }
    end

    context "with $HTTP_PROXY env" do
      let(:proxy_test_scheme) { :http }

      before(:each) do
        PROXY_ENV_VARS.each {|k| ENV.delete k }
        ENV['HTTP_PROXY'] = 'http://127.0.0.1:8083'
      end

      include_examples "*_PROXY var (testing var)"
    end

    context "with $http_proxy env" do
      let(:proxy_test_scheme) { :http }

      before(:each) do
        PROXY_ENV_VARS.each {|k| ENV.delete k }
        ENV['http_proxy'] = 'http://127.0.0.1:8083'
      end

      include_examples "*_PROXY var (testing var)"
    end

    context "with $HTTPS_PROXY env" do
      let(:proxy_test_scheme) { :https }

      before(:each) do
        PROXY_ENV_VARS.each {|k| ENV.delete k }
        ENV['HTTPS_PROXY'] = 'http://127.0.0.1:8083'
      end

      include_examples "*_PROXY var (testing var)"
    end

    context "with $https_proxy env" do
      let(:proxy_test_scheme) { :https }

      before(:each) do
        PROXY_ENV_VARS.each {|k| ENV.delete k }
        ENV['https_proxy'] = 'http://127.0.0.1:8083'
      end

      include_examples "*_PROXY var (testing var)"
    end

    context "with $ALL_PROXY env" do
      let(:proxy_test_scheme) { :https }

      before(:each) do
        PROXY_ENV_VARS.each {|k| ENV.delete k }
        ENV['ALL_PROXY'] = 'http://127.0.0.1:8083'
      end

      include_examples "*_PROXY var (testing var)"
    end
  end
end
