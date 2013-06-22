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

  ##
  # Partial implementation of RFC 1952 to extract the deflate stream from a gzip file
  class GZipHeader
    def initialize
      @state = :begin
      @data = ""
      @pos = 0
    end

    def finished?
      @state == :finish
    end

    def read(n, buffer)
      if (@pos + n) <= @data.size
        buffer << @data[@pos..(@pos + n - 1)]
        @pos += n
        return true
      else
        return false
      end
    end

    def readbyte
      if (@pos + 1) <= @data.size
        @pos += 1
        @data.getbyte(@pos - 1)
      end
    end

    def eof?
      @pos >= @data.size
    end

    def extract_stream(compressed)
      @data << compressed
      pos = @pos

      while !eof? && !finished?
        buffer = ""

        case @state
        when :begin
          break if !read(10, buffer)

          if buffer.getbyte(0) != 0x1f || buffer.getbyte(1) != 0x8b
            raise DecoderError.new("magic header not found")
          end

          if buffer.getbyte(2) != 0x08
            raise DecoderError.new("unknown compression method")
          end

          @flags = buffer.getbyte(3)
          if (@flags & 0xe0).nonzero?
            raise DecoderError.new("unknown header flags set")
          end

          # We don't care about these values, I'm leaving the code for reference
          # @time = buffer[4..7].unpack("V")[0] # little-endian uint32
          # @extra_flags = buffer.getbyte(8)
          # @os = buffer.getbyte(9)

          @state = :extra_length

        when :extra_length
          if (@flags & 0x04).nonzero?
            break if !read(2, buffer)
            @extra_length = buffer.unpack("v")[0] # little-endian uint16
            @state = :extra
          else
            @state = :extra
          end

        when :extra
          if (@flags & 0x04).nonzero?
            break if read(@extra_length, buffer)
            @state = :name
          else
            @state = :name
          end

        when :name
          if (@flags & 0x08).nonzero?
            while !(buffer = readbyte).nil?
              if buffer == 0
                @state = :comment
                break
              end
            end
          else
            @state = :comment
          end

        when :comment
          if (@flags & 0x10).nonzero?
            while !(buffer = readbyte).nil?
              if buffer == 0
                @state = :hcrc
                break
              end
            end
          else
            @state = :hcrc
          end

        when :hcrc
          if (@flags & 0x02).nonzero?
            break if !read(2, buffer)
            @state = :finish
          else
            @state = :finish
          end
        end
      end

      if finished?
        compressed[(@pos - pos)..-1]
      else
        ""
      end
    end
  end

  class GZip < Base
    def self.encoding_names
      %w(gzip compressed)
    end

    def decompress(compressed)
      @header ||= GZipHeader.new
      if !@header.finished?
        compressed = @header.extract_stream(compressed)
      end

      @zstream ||= Zlib::Inflate.new(-Zlib::MAX_WBITS)
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
