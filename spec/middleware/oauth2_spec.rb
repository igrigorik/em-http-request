describe EventMachine::Middleware::OAuth2 do
  it "should add an access token to a URI with no query parameters" do
    middleware = EventMachine::Middleware::OAuth2.new(:access_token => "fedcba9876543210")
    uri = Addressable::URI.parse("https://graph.facebook.com/me")
    middleware.update_uri! uri
    uri.to_s.should == "https://graph.facebook.com/me?access_token=fedcba9876543210"
  end

  it "should add an access token to a URI with query parameters" do
    middleware = EventMachine::Middleware::OAuth2.new(:access_token => "fedcba9876543210")
    uri = Addressable::URI.parse("https://graph.facebook.com/me?fields=photo")
    middleware.update_uri! uri
    uri.to_s.should == "https://graph.facebook.com/me?fields=photo&access_token=fedcba9876543210"
  end
end
