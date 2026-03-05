require "updog_ruby_client/version"
require "updog_ruby_client/config"
require "updog_ruby_client/thread_store"
require "updog_ruby_client/context"
require "updog_ruby_client/breadcrumbs"
require "updog_ruby_client/backtrace"
require "updog_ruby_client/notice"
require "updog_ruby_client/transport"
require "updog_ruby_client/http_transport"
require "updog_ruby_client/notice_sender"

module UpdogRubyClient
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Config.new
    end

    def reset!
      @configuration = Config.new
      Context.clear
      Breadcrumbs.clear
    end

    def notify(exception, opts = nil, **kwargs)
      return :ok unless enabled?

      normalized_exception = normalize_exception(exception)
      normalized_opts = normalize_opts(opts, kwargs)
      return :ok unless normalized_exception

      NoticeSender.send_notice(normalized_exception, normalized_opts)
      :ok
    rescue StandardError
      :ok
    end

    def notify_error(kind, reason, backtrace, opts = nil, **kwargs)
      return :ok unless enabled?

      NoticeSender.send_error(kind, reason, backtrace, normalize_opts(opts, kwargs))
      :ok
    rescue StandardError
      :ok
    end

    def context(data = nil, **kwargs, &block)
      if block
        Context.with(data, **kwargs, &block)
      else
        Context.set(data, **kwargs)
      end
    end

    def clear_context
      Context.clear
    end

    def with_context(data = nil, **kwargs, &block)
      Context.with(data, **kwargs, &block)
    end

    def add_breadcrumb(message, metadata = nil, category: nil, level: "info", **metadata_kwargs)
      Breadcrumbs.add(message, metadata, category: category, level: level, **metadata_kwargs)
    end

    def breadcrumb(message, metadata = nil, category: nil, level: "info", **metadata_kwargs, &block)
      if block
        Breadcrumbs.with(message, metadata, category: category, level: level, **metadata_kwargs, &block)
      else
        Breadcrumbs.add(message, metadata, category: category, level: level, **metadata_kwargs)
      end
    end

    def breadcrumbs
      Breadcrumbs.get
    end

    def clear_breadcrumbs
      Breadcrumbs.clear
    end

    def set_user(user = nil, id: nil, email: nil, name: nil, username: nil, **extra)
      payload = user.is_a?(Hash) ? user.dup : {}
      payload[:id] = id if id
      payload[:email] = email if email
      payload[:name] = name if name
      payload[:username] = username if username
      payload.merge!(extra) unless extra.empty?
      existing = Context.get[:user]
      payload = existing.merge(payload) if existing.is_a?(Hash)
      Context.set(user: payload)
    end

    alias_method :set_context, :context
    alias_method :merge_context, :context
    alias_method :with_breadcrumb, :breadcrumb

    private

    def normalize_exception(exception)
      return exception if exception.is_a?(Exception)
      return RuntimeError.new(exception) if exception.is_a?(String)
      return $! if exception.nil?

      RuntimeError.new(exception.to_s)
    end

    def normalize_opts(opts, kwargs)
      base = opts || {}
      raise ArgumentError, "notify options must be a Hash" unless base.is_a?(Hash)

      base.merge(kwargs)
    end

    def enabled?
      !configuration.api_key.to_s.strip.empty?
    end
  end
end
