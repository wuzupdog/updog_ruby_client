module UpdogRubyClient
  class NoticeSender
    class << self
      def send_notice(exception, opts = {})
        UpdogRubyClient.delivery_worker.enqueue(:notices, Notice.build(exception, opts))
      end

      def send_error(kind, reason, backtrace, opts = {})
        UpdogRubyClient.delivery_worker.enqueue(
          :notices,
          Notice.build_from_error(kind, reason, backtrace, opts)
        )
      end

      def send_deployment(attrs = {})
        UpdogRubyClient.delivery_worker.enqueue(:deployments, attrs)
      end
    end
  end
end
