require 'helper'
require 'fiber'

describe EventMachine::HttpRequest do
  context "with fibers" do
    it "should be transparent to connexion errors" do
      EventMachine.run do
        Fiber.new do
          f = Fiber.current
          http = EventMachine::HttpRequest.new('http://non-existing.domain/').get
          http.callback {failed(http)}
          http.errback {f.resume}
          Fiber.yield
          EventMachine.stop
        end.resume
      end
    end
  end
end


