require 'helper'

$: << 'lib' << '../lib'

require 'em-http/middleware/digest_auth'

describe 'Digest Auth Authentication header generation' do
  before :each do
    @reference_header = 'Digest username="digest_username", realm="DigestAuth_REALM", algorithm=MD5, uri="/", nonce="MDAxMzQzNzQwNjA2OmRjZjAyZDY3YWMyMWVkZGQ4OWE2Nzg3ZTY3YTNlMjg5", response="96829962ffc31fa2852f86dc7f9f609b", opaque="BzdNK3gsJ2ixTrBJ"'
  end

  it 'should generate the correct header'  do
    www_authenticate = 'Digest realm="DigestAuth_REALM", nonce="MDAxMzQzNzQwNjA2OmRjZjAyZDY3YWMyMWVkZGQ4OWE2Nzg3ZTY3YTNlMjg5", opaque="BzdNK3gsJ2ixTrBJ", stale=false, algorithm=MD5'

    params = {
      username: 'digest_username',
      password: 'digest_password'
    }

    middleware = EM::Middleware::DigestAuth.new(www_authenticate, params)
    middleware.build_auth_digest('GET', '/').should == @reference_header
  end

  it 'should not generate the same header for a different user' do
    www_authenticate = 'Digest realm="DigestAuth_REALM", nonce="MDAxMzQzNzQwNjA2OmRjZjAyZDY3YWMyMWVkZGQ4OWE2Nzg3ZTY3YTNlMjg5", opaque="BzdNK3gsJ2ixTrBJ", stale=false, algorithm=MD5'

    params = {
      username: 'digest_username_2',
      password: 'digest_password'
    }

    middleware = EM::Middleware::DigestAuth.new(www_authenticate, params)
    middleware.build_auth_digest('GET', '/').should_not == @reference_header
  end

  it 'should not generate the same header if the nounce changes' do
    www_authenticate = 'Digest realm="DigestAuth_REALM", nonce="MDAxMzQzNzQwNjA2OmRjZjAyZDY3YWMyMWVkZGQ4OWE2Nzg3ZTY3YTNlMjg6", opaque="BzdNK3gsJ2ixTrBJ", stale=false, algorithm=MD5'

    params = {
      username: 'digest_username_2',
      password: 'digest_password'
    }

    middleware = EM::Middleware::DigestAuth.new(www_authenticate, params)
    middleware.build_auth_digest('GET', '/').should_not == @reference_header
  end

end
