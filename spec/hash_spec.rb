require 'spec/helper'

describe Hash do
  
  describe ".to_params" do
    it "should transform a basic hash into HTTP POST Params" do
      {:a => "alpha", :b => "beta"}.to_params.should == "a=alpha&b=beta"
    end
    
    it "should transform a more complex hash into HTTP POST Params" do
      {:a => "a", :b => ["c", "d", "e"]}.to_params.should == "a=a&b[0]=c&b[1]=d&b[2]=e"
    end

    # Ruby 1.8 Hash is not sorted, so this test breaks randomly. Maybe once we're all on 1.9. ;-)
    # it "should transform a very complex hash into HTTP POST Params" do
    #    {:a => "a", :b => [{:c => "c", :d => "d"}, {:e => "e", :f => "f"}]}.to_params.should == "a=a&b[0][d]=d&b[0][c]=c&b[1][f]=f&b[1][e]=e"
    # end
  end
end
