module UpdogRubyClient
  module Transport
    class DeliveryError < StandardError; end

    class Base
      def post_json(_url, _payload, headers: {})
        raise NotImplementedError, "implement #post_json(url, payload, headers:)"
      end
    end
  end
end
