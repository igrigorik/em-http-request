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
        hydra = Typhoeus::Hydra.new
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
#| Typhoeus                     | 0.005322  |
#+------------------------------+-----------+
#| em-http-request (persistent) | 0.134937  |
#+------------------------------+-----------+
#| Excon                        | 0.172941  |
#+------------------------------+-----------+
#| Net::HTTP (persistent)       | 0.213400  |
#+------------------------------+-----------+
#| Net::HTTP                    | 0.216407  |
#+------------------------------+-----------+
#| HTTParty                     | 0.218760  |
#+------------------------------+-----------+
#| RestClient                   | 0.238830  |
#+------------------------------+-----------+
#| open-uri                     | 0.282000  |
#+------------------------------+-----------+
#| curb (persistent)            | 3.982839  |
#+------------------------------+-----------+
#| StreamlyFFI (persistent)     | 3.984747  |
#+------------------------------+-----------+
#| Excon (persistent)           | 4.019305  |
#+------------------------------+-----------+
#| em-http-request              | 15.034792 |
#+------------------------------+-----------+
