require_relative "test_helper"

class ThreadLocalBehaviorTest < Minitest::Test
  def setup
    UpdogRubyClient.reset!
  end

  def test_context_is_thread_local
    UpdogRubyClient.context(request_id: "main-thread")
    queue = Queue.new

    worker = Thread.new do
      UpdogRubyClient.context(request_id: "worker-thread")
      queue << UpdogRubyClient::Context.get
    end
    worker.join

    assert_equal({ request_id: "main-thread" }, UpdogRubyClient::Context.get)
    assert_equal({ request_id: "worker-thread" }, queue.pop)
  end

  def test_breadcrumbs_are_thread_local
    UpdogRubyClient.breadcrumb("main crumb")
    queue = Queue.new

    worker = Thread.new do
      UpdogRubyClient.breadcrumb("worker crumb")
      queue << UpdogRubyClient.breadcrumbs
    end
    worker.join

    assert_equal ["main crumb"], UpdogRubyClient.breadcrumbs.map { |crumb| crumb[:message] }
    assert_equal ["worker crumb"], queue.pop.map { |crumb| crumb[:message] }
  end

  def test_context_get_returns_defensive_copy
    UpdogRubyClient.context(user: { id: 1 })

    copy = UpdogRubyClient::Context.get
    copy[:user][:id] = 999

    assert_equal 1, UpdogRubyClient::Context.get[:user][:id]
  end

  def test_breadcrumb_get_returns_defensive_copy
    UpdogRubyClient.breadcrumb("query", sql: "SELECT 1")

    copy = UpdogRubyClient.breadcrumbs
    copy[0][:metadata][:sql] = "SELECT 2"

    assert_equal "SELECT 1", UpdogRubyClient.breadcrumbs[0][:metadata][:sql]
  end

  def test_breadcrumbs_are_bounded_to_max_size
    45.times { |i| UpdogRubyClient.breadcrumb("crumb #{i}") }

    crumbs = UpdogRubyClient.breadcrumbs
    assert_equal 40, crumbs.length
    assert_equal "crumb 5", crumbs.first[:message]
    assert_equal "crumb 44", crumbs.last[:message]
  end
end
