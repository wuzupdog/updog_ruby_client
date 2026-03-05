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

  # optional
  config.open_timeout = 2
  config.read_timeout = 5
  config.retries = 2
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

## Design notes

- Parity with Elixir client for `notify`, `notify_error`, thread-local context, breadcrumbs
- Fail-safe delivery: notify methods never raise into your application
- Pluggable transport via `config.transport`
- Default transport uses `Net::HTTP` with retry/backoff for transient failures
