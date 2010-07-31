module EventMachine

  # EventMachine based Multi request client, based on a streaming HTTPRequest class,
  # which allows you to open multiple parallel connections and return only when all
  # of them finish. (i.e. ideal for parallelizing workloads)
  #
  # == Example
  #
  #  EventMachine.run {
  #
  #   multi = EventMachine::MultiRequest.new
  #
  #   # add multiple requests to the multi-handler
  #   multi.add(EventMachine::HttpRequest.new('http://www.google.com/').get)
  #   multi.add(EventMachine::HttpRequest.new('http://www.yahoo.com/').get)
  #
  #    multi.callback  {
  #       p multi.responses[:succeeded]
  #       p multi.responses[:failed]
  #
  #       EventMachine.stop
  #    }
  #  }
  #

  class MultiRequest
    include EventMachine::Deferrable

    attr_reader :requests, :responses

    def initialize(conns=[], &block)
      @requests  = []
      @responses = {:succeeded => [], :failed => []}

      conns.each {|conn| add(conn)}
      callback(&block) if block_given?
    end

    def add(conn)
      @requests.push(conn)

      conn.callback { @responses[:succeeded].push(conn); check_progress }
      conn.errback  { @responses[:failed].push(conn); check_progress }
    end

    protected

    # invoke callback if all requests have completed
    def check_progress
      succeed(self) if (@responses[:succeeded].size +
                        @responses[:failed].size) == @requests.size
    end

  end
end
