require 'helper'
require 'fiber'

describe EventMachine::HttpRequest do
  context "with fibers" do

    it "should be transparent to connection errors" do
      EventMachine.run do
        Fiber.new do
          f = Fiber.current
          fired = false
          http = EventMachine::HttpRequest.new('http://non-existing.domain/', :connection_timeout => 0.1).get
          http.callback { failed(http) }
          http.errback { f.resume :errback }

          Fiber.yield.should == :errback
          EM.stop
        end.resume
      end
    end

  end
end
