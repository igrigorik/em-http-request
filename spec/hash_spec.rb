require 'spec/helper'

describe Hash do
  
  describe ".to_params" do
    it "should transform a basic hash into HTTP POST Params" do
      {:a => "alpha", :b => "beta"}.to_params.split("&").should include "a=alpha"
      {:a => "alpha", :b => "beta"}.to_params.split("&").should include "b=beta"
    end
    
    it "should transform a more complex hash into HTTP POST Params" do
      {:a => "a", :b => ["c", "d", "e"]}.to_params.split("&").should include "a=a"
      {:a => "a", :b => ["c", "d", "e"]}.to_params.split("&").should include "b[0]=c"
      {:a => "a", :b => ["c", "d", "e"]}.to_params.split("&").should include "b[1]=d"
      {:a => "a", :b => ["c", "d", "e"]}.to_params.split("&").should include "b[2]=e"
    end

    it "should transform a very complex hash into HTTP POST Params" do
      params = {:a => "a", :b => [{:c => "c", :d => "d"}, {:e => "e", :f => "f"}]}.to_params.split("&")
      params.should include "a=a"
      params.should include "b[0][d]=d"
    end
  end
end
