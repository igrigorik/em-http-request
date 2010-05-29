require 'rubygems'
require 'lib/em-http'

module KBHandler
  include EM::Protocols::LineText2

  def receive_line(data)
    p "Want to send: #{data}"
    p "Error status: #{$http.error?}"
    $http.send(data)
    p "After send"
  end
end

EventMachine.run {
  $http = EventMachine::HttpRequest.new("ws://localhost:8080/").get :timeout => 0

  $http.disconnect { puts 'oops' }
  $http.callback {
    puts "WebSocket connected!"
  }

  $http.stream { |msg|
    puts "Recieved: #{msg}"
  }

  EM.open_keyboard(KBHandler)
}
