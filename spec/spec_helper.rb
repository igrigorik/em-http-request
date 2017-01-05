PROXY_ENV_VARS = %w[HTTP_PROXY http_proxy HTTPS_PROXY https_proxy ALL_PROXY]

RSpec.configure do |config|
  proxy_envs = {}

  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.before :all do
    # Back-up ENV *_PROXY vars
    orig_proxy_envs = Hash[
      PROXY_ENV_VARS.select {|k| ENV.key? k }.map {|k| [k, ENV.delete(k)] }
    ]
    proxy_envs.replace(orig_proxy_envs)
  end

  config.after :all do
    # Restore ENV *_PROXY vars
    ENV.update(proxy_envs)
  end
end
