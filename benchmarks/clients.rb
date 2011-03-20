$: << './benchmarks'
require 'server'

require 'excon'
require 'httparty'
require 'net/http'
require 'open-uri'
require 'rest_client'
require 'tach'
require 'typhoeus'

url = 'http://127.0.0.1/10k.html'

with_server do
  Tach.meter(100) do

    tach('curb (persistent)') do |n|
      curb = Curl::Easy.new

      n.times do
        curb.url = url
        curb.http_get
        curb.body_str
      end
    end

    tach('em-http-request') do |n|
      EventMachine.run {
        count = 0
        error = 0

        n.times do
          http = EventMachine::HttpRequest.new(url).get

          http.callback {
            count += 1
            if count == n
              p [count, error]
              EM.stop
            end
          }

          http.errback {
            count += 1
            error += 1
            if count == n
              p [count, error]
              EM.stop
            end
          }
        end
      }
    end

    tach('em-http-request (persistent)') do |n|
      EventMachine.run {
        count = 0
        error = 0

        conn = EventMachine::HttpRequest.new(url)

        n.times do
          http = conn.get :keepalive => true
          http.callback {
            count += 1
            if count == n
              p [count, error]
              EM.stop
            end
          }

          http.errback {
            count += 1
            error += 1
            if count == n
              p [count, error]
              EM.stop
            end
          }
        end
      }
    end

    tach('Excon') do
      Excon.get(url).body
    end

    excon = Excon.new(url)
    tach('Excon (persistent)') do
      excon.request(:method => 'get').body
    end

    tach('HTTParty') do
      HTTParty.get(url).body
    end

    uri = Addressable::URI.parse(url)
    tach('Net::HTTP') do
      Net::HTTP.start(uri.host, uri.port) {|http| http.get(uri.path).body }
    end

    uri = Addressable::URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      tach('Net::HTTP (persistent)') do
        http.get(uri.path).body
      end
    end

    tach('open-uri') do
      open(url).read
    end

    tach('RestClient') do
      RestClient.get(url)
    end

    streamly = StreamlyFFI::Connection.new
    tach('StreamlyFFI (persistent)') do
      streamly.get(url)
    end

    tach('Typhoeus') do
      Typhoeus::Request.get(url).body
    end

  end
end


# +------------------------------+----------+
# | tach                         | total    |
# +------------------------------+----------+
# | em-http-request (persistent) | 0.016779 |
# +------------------------------+----------+
# | Excon (persistent)           | 0.019606 |
# +------------------------------+----------+
# | curb (persistent)            | 0.022034 |
# +------------------------------+----------+
# | Typhoeus                     | 0.027276 |
# +------------------------------+----------+
# | Excon                        | 0.034482 |
# +------------------------------+----------+
# | StreamlyFFI (persistent)     | 0.036474 |
# +------------------------------+----------+
# | em-http-request              | 0.041866 |
# +------------------------------+----------+
# | Net::HTTP (persistent)       | 0.098379 |
# +------------------------------+----------+
# | Net::HTTP                    | 0.103786 |
# +------------------------------+----------+
# | RestClient                   | 0.111841 |
# +------------------------------+----------+
# | HTTParty                     | 0.118632 |
# +------------------------------+----------+
# | open-uri                     | 0.170172 |
# +------------------------------+----------+
