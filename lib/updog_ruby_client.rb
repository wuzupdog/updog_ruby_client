require "updog_ruby_client/version"
require "updog_ruby_client/config"
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

    def notify(exception, opts = {})
      return :ok unless enabled?

      NoticeSender.send_notice(exception, opts)
      :ok
    rescue StandardError
      :ok
    end

    def notify_error(kind, reason, backtrace, opts = {})
      return :ok unless enabled?

      NoticeSender.send_error(kind, reason, backtrace, opts)
      :ok
    rescue StandardError
      :ok
    end

    def context(data)
      Context.set(data)
    end

    def add_breadcrumb(message, metadata = {})
      Breadcrumbs.add(message, metadata)
    end

    def enabled?
      !configuration.api_key.to_s.strip.empty?
    end
  end
end
