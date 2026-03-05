require_relative "test_helper"

class UpdogRubyClientTest < Minitest::Test
  def setup
    UpdogRubyClient.reset!
    UpdogRubyClient.configure do |c|
      c.api_key = "test-key"
      c.endpoint = "https://example.test"
    end
  end

  def test_notify_sends_notice_with_context_and_breadcrumbs
    fake = FakeTransport.new
    UpdogRubyClient.configure { |c| c.transport = fake }

    UpdogRubyClient.context(user_id: 42)
    UpdogRubyClient.add_breadcrumb("clicked", button: "save")

    err = RuntimeError.new("kaboom")
    err.set_backtrace(["app/models/user.rb:12:in `save!'"])

    result = UpdogRubyClient.notify(err, fingerprint: "abc123")

    assert_equal :ok, result
    assert_equal 1, fake.calls.length
    call = fake.calls.first
    assert_equal "https://example.test/api/v1/notices", call[:url]
    assert_equal "test-key", call[:headers]["X-API-Key"]
    assert_equal "RuntimeError", call[:payload][:error_class]
    assert_equal "kaboom", call[:payload][:message]
    assert_equal({ user_id: 42 }, call[:payload][:context])
    assert_equal "abc123", call[:payload][:fingerprint]
    assert_equal 1, call[:payload][:breadcrumbs].length
  end

  def test_notify_is_fail_safe
    fake = FakeTransport.new(raise_error: true)
    UpdogRubyClient.configure { |c| c.transport = fake }

    assert_equal :ok, UpdogRubyClient.notify(StandardError.new("oops"))
  end

  def test_notify_error_works_with_tuple_style
    fake = FakeTransport.new
    UpdogRubyClient.configure { |c| c.transport = fake }

    UpdogRubyClient.notify_error(:error, StandardError.new("tuple fail"), ["foo.rb:10:in `bar'"])

    payload = fake.calls.first[:payload]
    assert_equal "StandardError", payload[:error_class]
    assert_equal "tuple fail", payload[:message]
  end

  def test_disabled_when_api_key_missing
    UpdogRubyClient.configure { |c| c.api_key = nil }

    assert_equal false, UpdogRubyClient.enabled?
    assert_equal :ok, UpdogRubyClient.notify(StandardError.new("no-op"))
  end
end
