module UpdogRubyClient
  class NoticeSender
    class << self
      def send_notice(exception, opts = {})
        payload = Notice.build(exception, opts)
        deliver(payload)
      end

      def send_error(kind, reason, backtrace, opts = {})
        payload = Notice.build_from_error(kind, reason, backtrace, opts)
        deliver(payload)
      end

      def send_deployment(attrs = {})
        config = UpdogRubyClient.configuration
        transport = config.transport || HttpTransport.new(
          open_timeout: config.open_timeout,
          read_timeout: config.read_timeout,
          retries: config.retries
        )

        transport.post_json(
          config.deployments_url,
          attrs,
          headers: { "X-API-Key" => config.api_key.to_s }
        )
      end

      private

      def deliver(payload)
        config = UpdogRubyClient.configuration
        transport = config.transport || HttpTransport.new(
          open_timeout: config.open_timeout,
          read_timeout: config.read_timeout,
          retries: config.retries
        )

        transport.post_json(
          config.notices_url,
          payload,
          headers: { "X-API-Key" => config.api_key.to_s }
        )
      end
    end
  end
end
