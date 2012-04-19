$: << './benchmarks'
require 'server'

require 'excon'
require 'httparty'
require 'net/http'
require 'open-uri'
require 'rest_client'
require 'tach'
require 'typhoeus'

url = 'http://127.0.0.1:9292/data/10000'

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

    tach('Typhoeus') do |n|
        hydra = Typhoeus::Hydra.new( max_concurrency: 8 )
        hydra.disable_memoization
        count = 0
        error = 0
        n.times {
            req = Typhoeus::Request.new( url )
            req.on_complete do |res|
                count += 1
                error += 1 if !res.success?
                p [count, error] if count == n

            end
            hydra.queue( req )
        }
        hydra.run
    end

  end
end


#+------------------------------+-----------+
#| tach                         | total     |
#+------------------------------+-----------+
#| em-http-request (persistent) | 0.145512  |
#+------------------------------+-----------+
#| Excon                        | 0.181564  |
#+------------------------------+-----------+
#| RestClient                   | 0.253127  |
#+------------------------------+-----------+
#| Net::HTTP                    | 0.294412  |
#+------------------------------+-----------+
#| HTTParty                     | 0.305397  |
#+------------------------------+-----------+
#| open-uri                     | 0.307007  |
#+------------------------------+-----------+
#| Net::HTTP (persistent)       | 0.313716  |
#+------------------------------+-----------+
#| Typhoeus                     | 0.514725  |
#+------------------------------+-----------+
#| curb (persistent)            | 3.981700  |
#+------------------------------+-----------+
#| StreamlyFFI (persistent)     | 3.989063  |
#+------------------------------+-----------+
#| Excon (persistent)           | 4.018761  |
#+------------------------------+-----------+
#| em-http-request              | 15.025291 |
#+------------------------------+-----------+
