$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "updog_ruby_client"

class FakeTransport
  attr_reader :calls

  def initialize(raise_error: false)
    @calls = []
    @raise_error = raise_error
  end

  def post_json(url, payload, headers: {})
    raise UpdogRubyClient::Transport::DeliveryError, "boom" if @raise_error

    @calls << { url: url, payload: payload, headers: headers }
    :ok
  end
end
