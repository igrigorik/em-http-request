require 'zlib'
require 'stringio'

##
# Provides a unified callback interface to decompression libraries.
module EventMachine::HttpDecoders

  class DecoderError < StandardError
  end

  class << self
    def accepted_encodings
      DECODERS.inject([]) { |r,d| r + d.encoding_names }
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

  ##
  # Oneshot decompressor, due to lack of a streaming Gzip reader
  # implementation. We may steal code from Zliby to improve this.
  #
  # For now, do not put `gzip' or `compressed' in your accept-encoding
  # header if you expect much data through the :on_response interface.
  class GZip < Base
    def self.encoding_names
      %w(gzip compressed)
    end

    def decompress(compressed)
      @buf ||= ''
      @buf += compressed
      nil
    end

    def finalize
      begin
        Zlib::GzipReader.new(StringIO.new(@buf.to_s)).read
      rescue Zlib::Error
        raise DecoderError
      end
    end
  end

  DECODERS = [Deflate, GZip]

end
