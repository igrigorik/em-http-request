# context "websocket connection" do
#   # Spec: http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-55
#   #
#   # ws.onopen     = http.callback
#   # ws.onmessage  = http.stream { |msg| }
#   # ws.errback    = no connection
#   #
#
#   it "should invoke errback on failed upgrade" do
#     EventMachine.run {
#       http = EventMachine::HttpRequest.new('ws://127.0.0.1:8080/').get :timeout => 0
#
#       http.callback { failed(http) }
#       http.errback {
#         http.response_header.status.should == 200
#         EventMachine.stop
#       }
#     }
#   end
#
#   it "should complete websocket handshake and transfer data from client to server and back" do
#     EventMachine.run {
#       MSG = "hello bi-directional data exchange"
#
#       EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8085) do |ws|
#         ws.onmessage {|msg| ws.send msg}
#       end
#
#       http = EventMachine::HttpRequest.new('ws://127.0.0.1:8085/').get :timeout => 1
#       http.errback { failed(http) }
#       http.callback {
#         http.response_header.status.should == 101
#         http.response_header['CONNECTION'].should match(/Upgrade/)
#         http.response_header['UPGRADE'].should match(/WebSocket/)
#
#         # push should only be invoked after handshake is complete
#         http.send(MSG)
#       }
#
#       http.stream { |chunk|
#         chunk.should == MSG
#         EventMachine.stop
#       }
#     }
#   end
#
#   it "should split multiple messages from websocket server into separate stream callbacks" do
#     EM.run do
#       messages = %w[1 2]
#       recieved = []
#
#       EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8085) do |ws|
#         ws.onopen {
#           ws.send messages[0]
#           ws.send messages[1]
#         }
#       end
#
#       EventMachine.add_timer(0.1) do
#         http = EventMachine::HttpRequest.new('ws://127.0.0.1:8085/').get :timeout => 0
#         http.errback { failed(http) }
#         http.callback { http.response_header.status.should == 101 }
#         http.stream {|msg|
#           msg.should == messages[recieved.size]
#           recieved.push msg
#
#           EventMachine.stop if recieved.size == messages.size
#         }
#       end
#     end
#   end
#   end
# end
