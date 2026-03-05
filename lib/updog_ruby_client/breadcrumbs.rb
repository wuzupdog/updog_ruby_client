require "time"

module UpdogRubyClient
  module Breadcrumbs
    KEY = :updog_breadcrumbs
    MAX_BREADCRUMBS = 40

    module_function

    def add(message, metadata = {})
      crumb = {
        message: message.to_s,
        metadata: metadata,
        timestamp: Time.now.utc.iso8601
      }

      current = store[KEY] || []
      store[KEY] = ([crumb] + current).first(MAX_BREADCRUMBS)
      :ok
    end

    def get
      (store[KEY] || []).reverse
    end

    def clear
      store[KEY] = []
      :ok
    end

    def store
      Thread.current.thread_variable_get(:updog_store) ||
        Thread.current.thread_variable_set(:updog_store, {})
    end
  end
end
