$: << './benchmarks'
require 'server'

url = 'http://127.0.0.1:9292/data/1000'

with_server do
  Tach.meter(1000) do

    # excon = Excon.new(url)
    # tach('Excon (persistent)') do
    #   excon.request(:method => 'get').body
    # end
    #
    # tach('Excon') do
    #   Excon.get(url).body
    # end

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

    # tach('em-http-request (persistent)') do |n|
    #   EventMachine.run {
    #     count = 0
    #     conn = EventMachine::HttpRequest.new(url)
    #
    #     n.times do
    #       http = conn.get :keepalive => true
    #       http.callback {
    #         count += 1
    #         EM.stop if count == n
    #       }
    #
    #       http.errback {
    #         count += 1
    #         EM.stop if count == n
    #       }
    #     end
    #   }
    # end
  end
end

# [Excon (persistent), Excon, em-http-request, em-http-request (persistent)]
#
# +------------------------------+----------+
# | tach                         | total    |
# +------------------------------+----------+
# | em-http-request (persistent) | 1.691872 |
# +------------------------------+----------+
# | Excon (persistent)           | 1.754767 |
# +------------------------------+----------+
# | Excon                        | 2.271368 |
# +------------------------------+----------+
# | em-http-request              | 2.973122 |
# +------------------------------+----------+