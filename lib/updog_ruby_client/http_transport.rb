require "json"
require "net/http"
require "uri"
require "securerandom"
require "time"

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

    def initialize(open_timeout:, read_timeout:, retries:, on_retry: nil)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @retries = retries
      @on_retry = on_retry
    end

    def post_json(url, payload, headers: {})
      attempts = 0
      headers = headers.merge("X-Updog-Request-ID" => headers["X-Updog-Request-ID"] || "req_#{SecureRandom.uuid}")

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

          status = response.code.to_i
          raise Transport::PayloadTooLarge, "HTTP 413" if status == 413

          if retryable_status?(status) && attempts <= @retries
            @on_retry&.call
            sleep(retry_delay(response, attempts))
            next
          end

          error = retryable_status?(status) ? Transport::DeliveryError : Transport::PermanentError
          raise error, "HTTP #{response.code}: #{response.body}"
        rescue *RETRYABLE_ERRORS => e
          if attempts <= @retries
            @on_retry&.call
            sleep(full_jitter(attempts))
            next
          end

          raise Transport::DeliveryError, e.message
        end
      end
    end

    private

    def retryable_status?(status)
      status == 408 || status == 429 || status >= 500
    end

    def retry_delay(response, attempts)
      value = response["Retry-After"]
      return full_jitter(attempts) if value.nil? || value.empty?

      seconds = Integer(value, exception: false)
      return [seconds, 30].min if seconds && seconds >= 0

      delay = Time.httpdate(value) - Time.now
      [[delay, 0].max, 30].min
    rescue ArgumentError
      full_jitter(attempts)
    end

    def full_jitter(attempts)
      rand * [0.25 * (2**(attempts - 1)), 30].min
    end
  end
end
