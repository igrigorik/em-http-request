require 'zlib'
require 'stringio'

##
# Provides a unified callback interface to decompression libraries.
module EventMachine::HttpDecoders

  class DecoderError < StandardError
  end

  class << self
    def accepted_encodings
      DECODERS.inject([]) { |r, d| r + d.encoding_names }
    end

    def decoder_for_encoding(encoding)
      DECODERS.each { |d|
        return d if d.encoding_names.include? encoding
      }
      nil
    end
  end

  class Base
    def self.encoding_names
      name = to_s.split('::').last.downcase
      [name]
    end

    ##
    # chunk_callback:: [Block] To handle a decompressed chunk
    def initialize(&chunk_callback)
      @chunk_callback = chunk_callback
    end

    def <<(compressed)
      return unless compressed && compressed.size > 0

      decompressed = decompress(compressed)
      receive_decompressed decompressed
    end

    def finalize!
      decompressed = finalize
      receive_decompressed decompressed
    end

    private

    def receive_decompressed(decompressed)
      if decompressed && decompressed.size > 0
        @chunk_callback.call(decompressed)
      end
    end

    protected

    ##
    # Must return a part of decompressed
    def decompress(compressed)
      nil
    end

    ##
    # May return last part
    def finalize
      nil
    end
  end

  class Deflate < Base
    def decompress(compressed)
      begin
        @zstream ||= Zlib::Inflate.new(-Zlib::MAX_WBITS)
        @zstream.inflate(compressed)
      rescue Zlib::Error
        raise DecoderError
      end
    end

    def finalize
      return nil unless @zstream

      begin
        r = @zstream.inflate(nil)
        @zstream.close
        r
      rescue Zlib::Error
        raise DecoderError
      end
    end
  end

  class GZip < Base
    def self.encoding_names
      %w(gzip compressed)
    end

    def decompress(compressed)
      @zstream ||= Zlib::Inflate.new(Zlib::MAX_WBITS + 16)
      @zstream.inflate(compressed)
    rescue Zlib::Error
      raise DecoderError
    end

    def finalize
      if @zstream
        if !@zstream.finished?
          r = @zstream.finish
        end
        @zstream.close
        r
      else
        nil
      end
    rescue Zlib::Error
      raise DecoderError
    end

  end

  DECODERS = [Deflate, GZip]

end
