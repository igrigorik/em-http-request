module EventMachine

  # EventMachine based Multi request client, based on a streaming HTTPRequest class,
  # which allows you to open multiple parallel connections and return only when all
  # of them finish. (i.e. ideal for parallelizing workloads)
  #
  # The responses will have the same order as the requests were given/added.
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

    attr_reader :requests

    def initialize(conns=[], &block)
      @requests  = []
      @responses = []
      @status    = []
      @index     = 0

      conns.each {|conn| add(conn)}
      callback(&block) if block_given?
    end

    def add(conn)
      @requests.push(conn)

      index = @index
      @index += 1

      conn.callback { @responses[index] = conn; @status[index] = :succeeded; check_progress }
      conn.errback  { @responses[index] = conn; @status[index] = :failed;    check_progress }
    end

    def responses
      @status.zip(@responses).inject({:succeeded => [], :failed => []}) { |result, response|
        status, conn = response
        result[status].push(conn)
        result
      }
    end

    protected

    # invoke callback if all requests have completed
    def check_progress
      succeed(self) if @status.compact.size == @requests.size
    end

  end
end
