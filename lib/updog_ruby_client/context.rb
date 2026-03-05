require "updog_ruby_client/thread_store"

module UpdogRubyClient
  module Context
    KEY = :updog_context

    module_function

    def set(data = nil, **kwargs)
      normalized = normalize(data, kwargs)
      raise ArgumentError, "context must be a Hash" unless normalized.is_a?(Hash)

      store[KEY] = get.merge(normalized)
      :ok
    end

    def with(data = nil, **kwargs)
      return :ok unless block_given?

      previous = get
      set(data, **kwargs)
      yield
    ensure
      store[KEY] = previous
    end

    def get
      duplicate(store[KEY] || {})
    end

    def clear
      store[KEY] = {}
      :ok
    end

    def merge(data = nil, **kwargs)
      set(data, **kwargs)
    end

    def store
      ThreadStore.store
    end

    def normalize(data, kwargs)
      if data && !data.is_a?(Hash)
        raise ArgumentError, "context must be a Hash"
      end

      merged = {}
      merged.merge!(data) if data
      merged.merge!(kwargs) unless kwargs.empty?
      merged
    end

    def duplicate(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), h| h[k] = duplicate(v) }
      when Array
        value.map { |item| duplicate(item) }
      else
        value
      end
    end
  end
end
