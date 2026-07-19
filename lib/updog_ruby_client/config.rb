module UpdogRubyClient
  class Config
    DEFAULT_ENDPOINT = "https://wuzupdog.com".freeze
    DEFAULT_ENVIRONMENT = "development".freeze
    DEFAULT_OPEN_TIMEOUT = 2
    DEFAULT_READ_TIMEOUT = 5
    DEFAULT_RETRIES = 3
    DEFAULT_FLUSH_INTERVAL = 5.0
    DEFAULT_MAX_QUEUE_RECORDS = 2_048
    DEFAULT_MAX_QUEUE_BYTES = 8 * 1024 * 1024
    DEFAULT_MAX_RECORD_BYTES = 64 * 1024
    DEFAULT_MAX_BATCH_RECORDS = 512
    DEFAULT_MAX_BATCH_BYTES = 512 * 1024

    attr_accessor :api_key, :endpoint, :environment, :transport,
                  :open_timeout, :read_timeout, :retries, :service, :release,
                  :flush_interval, :max_queue_records, :max_queue_bytes,
                  :max_record_bytes, :max_batch_records, :max_batch_bytes

    def initialize
      @api_key = ENV["UPDOG_API_KEY"]
      @endpoint = ENV.fetch("UPDOG_ENDPOINT", DEFAULT_ENDPOINT)
      @environment = ENV.fetch("UPDOG_ENVIRONMENT", DEFAULT_ENVIRONMENT)
      @transport = nil
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @read_timeout = DEFAULT_READ_TIMEOUT
      @retries = DEFAULT_RETRIES
      @service = ENV.fetch("UPDOG_SERVICE", "")
      @release = ENV.fetch("UPDOG_RELEASE", "")
      @flush_interval = DEFAULT_FLUSH_INTERVAL
      @max_queue_records = DEFAULT_MAX_QUEUE_RECORDS
      @max_queue_bytes = DEFAULT_MAX_QUEUE_BYTES
      @max_record_bytes = DEFAULT_MAX_RECORD_BYTES
      @max_batch_records = DEFAULT_MAX_BATCH_RECORDS
      @max_batch_bytes = DEFAULT_MAX_BATCH_BYTES
    end

    def notices_url
      "#{endpoint}/api/v1/notices/bulk"
    end

    def deployments_url
      "#{endpoint}/api/v1/deployments"
    end
  end
end
