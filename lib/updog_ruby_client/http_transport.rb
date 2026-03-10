require "json"
require "net/http"
require "uri"

module UpdogRubyClient
  class HttpTransport < Transport::Base
    RETRYABLE_ERRORS = [
      Net::OpenTimeout,
      Net::ReadTimeout,
      IOError,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      SocketError,
      Timeout::Error
    ].freeze

    def initialize(open_timeout:, read_timeout:, retries:)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @retries = retries
    end

    def post_json(url, payload, headers: {})
      attempts = 0

      loop do
        attempts += 1

        begin
          uri = URI.parse(url)
          req = Net::HTTP::Post.new(uri)
          req["Content-Type"] = "application/json"
          headers.each { |k, v| req[k] = v }
          req.body = JSON.generate(payload)

          response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: @open_timeout, read_timeout: @read_timeout) do |http|
            http.request(req)
          end

          return :ok if response.code.to_i.between?(200, 299)

          if response.code.to_i >= 500 && attempts <= @retries + 1
            sleep(0.1 * attempts)
            next
          end

          raise Transport::DeliveryError, "HTTP #{response.code}: #{response.body}"
        rescue *RETRYABLE_ERRORS => e
          if attempts <= @retries
            sleep(0.1 * attempts)
            next
          end

          raise Transport::DeliveryError, e.message
        end
      end
    end
  end
end
