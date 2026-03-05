module UpdogRubyClient
  class Config
    DEFAULT_ENDPOINT = "https://wuzupdog.com".freeze
    DEFAULT_ENVIRONMENT = "development".freeze
    DEFAULT_OPEN_TIMEOUT = 2
    DEFAULT_READ_TIMEOUT = 5
    DEFAULT_RETRIES = 2

    attr_accessor :api_key, :endpoint, :environment, :transport,
                  :open_timeout, :read_timeout, :retries

    def initialize
      @api_key = ENV["UPDOG_API_KEY"]
      @endpoint = ENV.fetch("UPDOG_ENDPOINT", DEFAULT_ENDPOINT)
      @environment = ENV.fetch("UPDOG_ENVIRONMENT", DEFAULT_ENVIRONMENT)
      @transport = nil
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @read_timeout = DEFAULT_READ_TIMEOUT
      @retries = DEFAULT_RETRIES
    end

    def notices_url
      "#{endpoint}/api/v1/notices"
    end
  end
end
