# -*- encoding: utf-8 -*-

require 'helper'

describe EventMachine::HttpEncoding do
  include EventMachine::HttpEncoding

  it "should transform a basic hash into HTTP POST Params" do
    form_encode_body({:a => "alpha", :b => "beta"}).should == "a=alpha&b=beta"
  end

  it "should transform a more complex hash into HTTP POST Params" do
    form_encode_body({:a => "a", :b => ["c", "d", "e"]}).should == "a=a&b[0]=c&b[1]=d&b[2]=e"
  end

  it "should transform a very complex hash into HTTP POST Params" do
    params = form_encode_body({:a => "a", :b => [{:c => "c", :d => "d"}, {:e => "e", :f => "f"}]})
    # 1.8.7 does not have ordered hashes.
    params.split(/&/).sort.join('&').should == "a=a&b[0][c]=c&b[0][d]=d&b[1][e]=e&b[1][f]=f"
  end

  it "should escape values" do
    params = form_encode_body({:stuff => 'string&string'})
    params.should == "stuff=string%26string"
  end

  it "should escape keys" do
    params = form_encode_body({'bad&str'=> {'key&key' => [:a, :b]}})
    params.should == 'bad%26str[key%26key][0]=a&bad%26str[key%26key][1]=b'
  end

  it "should escape keys and values" do
    params = form_encode_body({'bad&str'=> {'key&key' => ['bad+&stuff', '[test]']}})
    params.should == "bad%26str[key%26key][0]=bad%2B%26stuff&bad%26str[key%26key][1]=%5Btest%5D"
  end

  it "should not issue warnings on non-ASCII encodings" do
    # I don't know how to check for ruby warnings.
    params = escape('valö')
    params = escape('valö'.encode('ISO-8859-15'))
  end

  # xit "should be fast on long string escapes" do
  #   s = Time.now
  #   5000.times { |n| form_encode_body({:a => "{a:'b', d:'f', g:['a','b']}"*50}) }
  #   (Time.now - s).should satisfy { |t| t < 1.5 }
  # end

end
