# updog_ruby_client

Ruby client for [Updog](https://wuzupdog.com) error reporting.

## Install

Add this line to your app's Gemfile:

```ruby
gem "updog_ruby_client", git: "https://github.com/swanny85/updog_ruby_client"
```

## Configure

```ruby
require "updog_ruby_client"

UpdogRubyClient.configure do |config|
  config.api_key = ENV["UPDOG_API_KEY"]
  config.endpoint = ENV.fetch("UPDOG_ENDPOINT", "https://wuzupdog.com")
  config.environment = ENV.fetch("UPDOG_ENVIRONMENT", "production")
  config.service = "checkout-api"
  config.release = ENV["RELEASE_VERSION"]

  # optional
  config.open_timeout = 2
  config.read_timeout = 5
  config.retries = 3
end
```

## API

### Report exceptions

```ruby
begin
  dangerous_call
rescue => e
  UpdogRubyClient.notify(
    e,
    fingerprint: "billing-timeout",
    request: { path: "/checkout" },
    tags: %w[billing timeout]
  )
end
```

### Report tuple-style errors

```ruby
UpdogRubyClient.notify_error(:error, StandardError.new("boom"), caller)
```

### Report plain messages

```ruby
UpdogRubyClient.notify("Background job failed to deserialize payload")
```

### Report deployments

```ruby
UpdogRubyClient.notify_deployment(
  environment: "production",
  service: "api",
  version: "v1.2.3",
  sha: "abc123"
)
```

### Context helpers (Honeybadger/AppSignal-style)

```ruby
UpdogRubyClient.context(user_id: 123, account_id: "acc_456")
UpdogRubyClient.set_user(id: "u_123", email: "dev@example.com")

UpdogRubyClient.with_context(job_id: "job_99") do
  perform_job
end

UpdogRubyClient.clear_context
```

### Breadcrumb helpers

```ruby
UpdogRubyClient.breadcrumb("clicked button", { button: "subscribe" }, category: "ui")

UpdogRubyClient.with_breadcrumb("sync started", { source: "billing" }, category: "job", level: :info) do
  sync_customer
end

UpdogRubyClient.clear_breadcrumbs
```

Breadcrumbs and context are stored in thread-local state so concurrent requests stay isolated.

## Delivery behavior

`notify`, `notify_error`, and `notify_deployment` only enqueue work into a bounded in-memory queue; they do not wait for HTTP. A single worker bulk-submits errors every five seconds (up to 512 records or 512 KiB) with defaults of 2,048 queued records, 8 MiB total queue memory, and 64 KiB per record. Full queues drop new telemetry instead of blocking or growing without limit, and error records can evict lower-priority deployment markers.

The HTTP transport retries network failures, `408`, `429`, and `5xx` three times using full-jitter exponential backoff and honors `Retry-After`. It keeps a stable request ID across retries, splits batches after `413`, and does not retry permanent client errors. The queue is intentionally in-memory only.

Use a bounded flush for short-lived processes and shutdown hooks:

```ruby
UpdogRubyClient.flush(5.0)
UpdogRubyClient.delivery_stats
UpdogRubyClient.shutdown(5.0)
```

An `at_exit` hook performs the same bounded shutdown automatically.

## Design notes

- Parity with Elixir client for `notify`, `notify_error`, thread-local context, breadcrumbs
- Fail-safe delivery: notify methods never raise into your application
- Pluggable transport via `config.transport`
- Default transport uses `Net::HTTP` with classified retries, idempotency, and `Retry-After`
