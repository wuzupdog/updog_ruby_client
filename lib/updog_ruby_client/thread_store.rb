module UpdogRubyClient
  module ThreadStore
    module_function

    def store
      Thread.current.thread_variable_get(:updog_store) ||
        Thread.current.thread_variable_set(:updog_store, {})
    end
  end
end
