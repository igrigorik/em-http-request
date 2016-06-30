require 'helper'

describe EventMachine::HttpDecoders::GZip do

  let(:compressed) {
    compressed = ["1f8b08089668a6500003686900cbc8e402007a7a6fed03000000"].pack("H*")
  }

  it "should extract the stream of a vanilla gzip" do
    header = EventMachine::HttpDecoders::GZipHeader.new
    stream = header.extract_stream(compressed)

    stream.unpack("H*")[0].should eq("cbc8e402007a7a6fed03000000")
  end

  it "should decompress a vanilla gzip" do
    decompressed = ""

    gz = EventMachine::HttpDecoders::GZip.new do |data|
      decompressed << data
    end

    gz << compressed
    gz.finalize!

    decompressed.should eq("hi\n")
  end

  it "should decompress a vanilla gzip file byte by byte" do
    decompressed = ""

    gz = EventMachine::HttpDecoders::GZip.new do |data|
      decompressed << data
    end

    compressed.each_char do |byte|
      gz << byte
    end

    gz.finalize!

    decompressed.should eq("hi\n")
  end

  it "should decompress a large file" do
    decompressed = ""

    gz = EventMachine::HttpDecoders::GZip.new do |data|
      decompressed << data
    end

    gz << File.read(File.dirname(__FILE__) + "/fixtures/gzip-sample.gz")

    gz.finalize!

    decompressed.size.should eq(32907)
  end

  it "should not care how many chunks the file is split up into" do
    examples = [
      ["\x1F", "\x8B", "\b", "\x00", "\x00", "\x00", "\x00", "\x00", "\x00", "\x00", "\xF3", "\xCB", "/", "Q", "p\xCB/\xCDK\x01\x00M\x8Ct\xB1\t\x00\x00\x00"],
      ["\x1F", "\x8B", "\b", "\x00", "\x00", "\x00", "\x00", "\x00\x00\x00\xF3\xCB/Qp\xCB/\xCDK\x01\x00M\x8Ct\xB1\t\x00\x00\x00"]
    ]

    examples.each do |example|
      decompressed = ""

      gz = EventMachine::HttpDecoders::GZip.new do |data|
        decompressed << data
      end

      example.each do |bytes|
        gz << bytes
      end

      gz.finalize!

      decompressed.should eq("Not Found")
    end
  end

  it "should fail with a DecoderError if not a gzip file" do
    not_a_gzip = ["1f8c08089668a650000"].pack("H*")
    header = EventMachine::HttpDecoders::GZipHeader.new

    lambda {
      header.extract_stream(not_a_gzip)
    }.should raise_exception(EventMachine::HttpDecoders::DecoderError)
  end

end
