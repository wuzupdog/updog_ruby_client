require "socket"

module UpdogRubyClient
  class Notice
    class << self
      def build(exception, opts = {})
        stacktrace = opts.fetch(:backtrace, exception.backtrace)

        {
          error_class: exception.class.to_s,
          message: exception.message,
          stacktrace: Backtrace.format(stacktrace),
          breadcrumbs: Breadcrumbs.get,
          context: Context.get,
          request: opts.fetch(:request, {}),
          environment: UpdogRubyClient.configuration.environment,
          hostname: Socket.gethostname,
          fingerprint: opts[:fingerprint],
          tags: opts.fetch(:tags, []),
          custom_data: opts.fetch(:custom_data, {})
        }
      end

      def build_from_error(kind, reason, backtrace, opts = {})
        error_class = if kind == :error && reason.respond_to?(:class)
                        reason.class.to_s
                      else
                        kind.to_s
                      end

        message = if reason.respond_to?(:message)
                    reason.message
                  else
                    reason.to_s
                  end

        {
          error_class: error_class,
          message: message,
          stacktrace: Backtrace.format(backtrace),
          breadcrumbs: Breadcrumbs.get,
          context: Context.get,
          request: opts.fetch(:request, {}),
          environment: UpdogRubyClient.configuration.environment,
          hostname: Socket.gethostname,
          fingerprint: opts[:fingerprint],
          tags: opts.fetch(:tags, []),
          custom_data: opts.fetch(:custom_data, {})
        }
      end
    end
  end
end
