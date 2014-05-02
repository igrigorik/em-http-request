require 'helper'

describe EventMachine::HttpDecoders::GZip do

  let(:compressed) {
    compressed = ["1f8b08089668a6500003686900cbc8e402007a7a6fed03000000"].pack("H*")
  }

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
  
  it "should decompress a vanilla gzip file from various-sized chunks" do
    decompressed = ""

    gz = EventMachine::HttpDecoders::GZip.new do |data|
      decompressed << data
    end
    
    gz << compressed[0...1]
    gz << compressed[1...2]
    gz << compressed[2...3]
    gz << compressed[3..-1]
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

  it "should fail with a DecoderError if not a gzip file" do
    not_a_gzip = ["1f8c08089668a650000"].pack("H*")

    lambda {
      gz = EventMachine::HttpDecoders::GZip.new
      
      gz << not_a_gzip
      
      gz.finalize!
      
    }.should raise_exception(EventMachine::HttpDecoders::DecoderError)
  end

end
