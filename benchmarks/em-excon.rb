$: << './benchmarks'
require 'server'

url = 'http://127.0.0.1/10k.html'

with_server do
  Tach.meter(100) do

    excon = Excon.new(url)
    tach('Excon (persistent)') do
      excon.request(:method => 'get').body
    end

    tach('Excon') do
      Excon.get(url).body
    end

    tach('em-http-request') do |n|
      EventMachine.run {
        count = 0
        error = 0
        n.times do
          EM.next_tick do
            http = EventMachine::HttpRequest.new(url, :connect_timeout => 1).get

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
  end
end

# +------------------------------+----------+
# | tach                         | total    |
# +------------------------------+----------+
# | em-http-request (persistent) | 0.018133 |
# +------------------------------+----------+
# | Excon (persistent)           | 0.023975 |
# +------------------------------+----------+
# | Excon                        | 0.032877 |
# +------------------------------+----------+
# | em-http-request              | 0.042891 |
# +------------------------------+----------+