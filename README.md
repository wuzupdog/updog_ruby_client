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
  UpdogRubyClient.notify(e, fingerprint: "billing-timeout", request: { path: "/checkout" })
end
```

### Report tuple-style errors

```ruby
UpdogRubyClient.notify_error(:error, StandardError.new("boom"), caller)
```

### Add context and breadcrumbs

```ruby
UpdogRubyClient.context(user_id: 123, account_id: "acc_456")
UpdogRubyClient.add_breadcrumb("clicked button", button: "subscribe")
```

## Design notes

- Parity with Elixir client for `notify`, `notify_error`, process-local context, breadcrumbs
- Fail-safe delivery: notify methods never raise into your application
- Pluggable transport via `config.transport`
- Default transport uses `Net::HTTP` with retry/backoff for transient failures
