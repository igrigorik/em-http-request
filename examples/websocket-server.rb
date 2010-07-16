require 'rubygems'
require 'em-websocket'

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
  ws.onopen    { ws.send "Hello Client!"}
  ws.onmessage { |msg| p "got: #{msg}"; ws.send "Pong: #{msg}" }
  ws.onclose   { puts "WebSocket closed" }
end
