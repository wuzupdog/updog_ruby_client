module UpdogRubyClient
  module Context
    KEY = :updog_context

    module_function

    def set(data)
      raise ArgumentError, "context must be a Hash" unless data.is_a?(Hash)

      store[KEY] = get.merge(data)
      :ok
    end

    def get
      store[KEY] || {}
    end

    def clear
      store[KEY] = {}
      :ok
    end

    def store
      Thread.current.thread_variable_get(:updog_store) ||
        Thread.current.thread_variable_set(:updog_store, {})
    end
  end
end
