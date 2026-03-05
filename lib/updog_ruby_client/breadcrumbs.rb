require "time"
require "updog_ruby_client/thread_store"

module UpdogRubyClient
  module Breadcrumbs
    KEY = :updog_breadcrumbs
    MAX_BREADCRUMBS = 40

    module_function

    def add(message, metadata = nil, category: nil, level: "info", **metadata_kwargs)
      normalized_metadata = normalize_metadata(metadata, metadata_kwargs)
      crumb = {
        message: message.to_s,
        metadata: normalized_metadata,
        category: category,
        level: level.to_s,
        timestamp: Time.now.utc.iso8601
      }

      current = store[KEY] || []
      current << crumb
      current.shift while current.length > MAX_BREADCRUMBS
      store[KEY] = current
      :ok
    end

    def with(message, metadata = nil, category: nil, level: "info", **metadata_kwargs)
      add(message, metadata, category: category, level: level, **metadata_kwargs)
      return :ok unless block_given?

      yield
    end

    def get
      duplicate(store[KEY] || [])
    end

    def clear
      store[KEY] = []
      :ok
    end

    def store
      ThreadStore.store
    end

    def normalize_metadata(metadata, metadata_kwargs)
      base = metadata || {}
      raise ArgumentError, "breadcrumb metadata must be a Hash" unless base.is_a?(Hash)

      base = base.merge(metadata_kwargs) unless metadata_kwargs.empty?

      duplicate(base)
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
