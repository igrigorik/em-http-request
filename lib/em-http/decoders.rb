require 'zlib'

##
# Provides a unified callback interface to decompression libraries.
module EventMachine::HTTPDecoders

  class << self
    def accepted_encodings
      DECODERS.map { |d| d.to_s }
    end

    def decoder_for_encoding(encoding)
      DECODERS.each { |d|
        return d if encoding == d.to_s
      }
      nil
    end
  end

  class Base
    ##
    # chunk_callback:: [Block] To handle a decompressed chunk
    def initialize(&chunk_callback)
      @chunk_callback = chunk_callback
      @decompressor = nil  # Initialized on demand
    end

    def <<(compressed)
      return unless compressed && compressed.size > 0

      @decompressor ||= make_decompressor
      decompressed = decompress(@decompressor, compressed)
      receive_decompressed decompressed
    end

    def finalize!
      decompressed = finalize(@decompressor)
      @decompressor = nil
      receive_decompressed decompressed
    end
    
    def self.to_s
      super.split('::').last.downcase
    end

    private

    def receive_decompressed(decompressed)
      if decompressed && decompressed.size > 0
        @chunk_callback.call(decompressed)
      end
    end

    protected

    ##
    # Supposed to return a new decompression library instance, such as
    # GZipReader.
    def make_decompressor
      raise 'Abstract'
    end
    
    ##
    # Must return a part of decompressed
    def decompress(decompressor, compressed)
      raise 'Abstract'
    end

    ##
    # May return last part
    def finalize(decompressor)
      nil
    end
  end

  class Deflate < Base
    def make_decompressor
      Zlib::Inflate.new(nil)
    end
    
    def decompress(zstream, compressed)
      zstream.inflate(compressed)
    end

    def finalize(zstream)
      r = zstream.inflate(nil)
      zstream.close
      r
    end
  end

  ##
  # Oneshot decompressor, due to lack of a streaming Gzip reader
  # implementation. We may steal code from Zliby to improve this.
  #
  # For now, do not put `gzip' or `compressed' in your accept-encoding
  # header if you expect much data through the :on_response interface.
  class GZip < Base
    def make_decompressor
      @buf = ""
      true
    end

    def decompress(a, compressed)
      @buf += compressed
      nil
    end

    def finalize(a)
      Zlib::GzipReader.new(StringIO.new(@buf)).read
    end
  end

  DECODERS = [Deflate, GZip]

end

    
