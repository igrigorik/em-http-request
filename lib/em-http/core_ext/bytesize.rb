# bytesize was introduced in 1.8.7+
if RUBY_VERSION <= "1.8.6"
  class String
    def bytesize; self.size; end
  end
end
