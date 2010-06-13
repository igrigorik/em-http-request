# bytesize was introduced in 1.8.7+
# TODO: WOOPS under 1.9!
if Object::VERSION <= "1.8.6"
  class String
    def bytesize; self.size; end
  end
end