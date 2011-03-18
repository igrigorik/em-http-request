$: << './benchmarks'
require 'server'

require 'excon'
require 'httparty'
require 'net/http'
require 'open-uri'
require 'rest_client'
require 'tach'
require 'typhoeus'

url = 'http://localhost:9292/data/1000'

with_server do
  Tach.meter(1000) do

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

        n.times do
          http = EventMachine::HttpRequest.new(url).get

          http.callback {
            count += 1
            EM.stop if count == n
          }

          http.errback {
            count += 1
            EM.stop if count == n
          }
        end
      }
    end

    tach('em-http-request (persistent)') do |n|
      EventMachine.run {
        count = 0
        conn = EventMachine::HttpRequest.new(url)

        n.times do
          http = conn.get :keepalive => true
          http.callback {
            count += 1
            EM.stop if count == n
          }

          http.errback {
            count += 1
            EM.stop if count == n
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

    tach('Net::HTTP') do
      # Net::HTTP.get('localhost', '/data/1000', 9292)
      Net::HTTP.start('localhost', 9292) {|http| http.get('/data/1000').body }
    end

    Net::HTTP.start('localhost', 9292) do |http|
      tach('Net::HTTP (persistent)') do
        http.get('/data/1000').body
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
# | em-http-request (persistent) | 1.769685 |
# +------------------------------+----------+
# | Excon (persistent)           | 1.810310 |
# +------------------------------+----------+
# | Typhoeus                     | 1.971168 |
# +------------------------------+----------+
# | curb (persistent)            | 1.975028 |
# +------------------------------+----------+
# | StreamlyFFI (persistent)     | 2.101071 |
# +------------------------------+----------+
# | Excon                        | 2.427039 |
# +------------------------------+----------+
# | Net::HTTP                    | 2.891856 |
# +------------------------------+----------+
# | em-http-request              | 3.037968 |
# +------------------------------+----------+
# | HTTParty                     | 3.043875 |
# +------------------------------+----------+
# | Net::HTTP (persistent)       | 3.094460 |
# +------------------------------+----------+
# | RestClient                   | 3.174572 |
# +------------------------------+----------+
# | open-uri                     | 3.467549 |
# +------------------------------+----------+