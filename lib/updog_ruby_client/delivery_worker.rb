require "json"
require "securerandom"
require "socket"
require "time"

module UpdogRubyClient
  class DeliveryWorker
    Record = Struct.new(:signal, :payload, :bytes, :priority, keyword_init: true)

    def initialize
      @mutex = Mutex.new
      @condition = ConditionVariable.new
      @queue = []
      @queue_bytes = 0
      @inflight = 0
      @flush_requested = false
      @stopping = false
      @stats = { queued: 0, sent: 0, retried: 0, dropped: Hash.new(0) }
      @thread = Thread.new { run }
      @thread.name = "updog-delivery" if @thread.respond_to?(:name=)
    end

    def enqueue(signal, payload)
      normalized = normalize(signal, payload)
      bytes = JSON.generate(normalized).bytesize
      record = Record.new(signal: signal, payload: normalized, bytes: bytes, priority: priority(signal))
      config = UpdogRubyClient.configuration

      @mutex.synchronize do
        return drop(:record_too_large) if bytes > config.max_record_bytes

        make_room(record, config)
        return drop(:queue_full) unless room?(record, config)

        @queue << record
        @queue_bytes += bytes
        @stats[:queued] += 1
        @condition.signal if @queue.length == 1 || batch_ready?(config)
      end

      :ok
    rescue JSON::GeneratorError, EncodingError
      @mutex.synchronize { drop(:encoding_error) }
      :ok
    rescue StandardError
      @mutex.synchronize { drop(:enqueue_error) }
      :ok
    end

    def flush(timeout = 5.0)
      deadline = monotonic + [timeout.to_f, 0].max

      @mutex.synchronize do
        @flush_requested = true
        @condition.signal

        until @queue.empty? && @inflight.zero?
          remaining = deadline - monotonic
          return :timeout if remaining <= 0

          @condition.wait(@mutex, remaining)
        end
      end

      :ok
    end

    def shutdown(timeout = 5.0)
      result = flush(timeout)

      @mutex.synchronize do
        if result == :timeout
          @stats[:dropped][:shutdown_timeout] += @queue.length
          @queue.clear
          @queue_bytes = 0
        end

        @stopping = true
        @condition.broadcast
      end

      @thread.join([timeout.to_f, 0].max)
      @thread.kill if @thread.alive?
      result
    end

    def stats
      @mutex.synchronize do
        {
          queued: @stats[:queued],
          sent: @stats[:sent],
          retried: @stats[:retried],
          dropped: @stats[:dropped].dup,
          queue_records: @queue.length,
          queue_bytes: @queue_bytes,
          in_flight: @inflight
        }
      end
    end

    private

    def run
      loop do
        batch = next_batch
        break unless batch

        result = deliver_batch(batch)

        @mutex.synchronize do
          if result == :ok
            @stats[:sent] += batch.length
          else
            @stats[:dropped][result] += batch.length
          end

          @inflight = 0
          @condition.broadcast
        end
      end
    rescue StandardError
      @mutex.synchronize do
        @stats[:dropped][:worker_crash] += @inflight
        @inflight = 0
        @condition.broadcast
      end
    end

    def next_batch
      @mutex.synchronize do
        loop do
          return nil if @stopping && @queue.empty?

          if @queue.empty?
            @condition.wait(@mutex)
            next
          end

          config = UpdogRubyClient.configuration
          @condition.wait(@mutex, config.flush_interval) unless @flush_requested || batch_ready?(config) || @stopping
          next if @queue.empty?

          batch = take_batch(config)
          @flush_requested = !@queue.empty?
          @inflight = batch.length
          return batch
        end
      end
    end

    def take_batch(config)
      signal = @queue.first.signal
      record_limit = signal == :deployments ? 1 : config.max_batch_records
      selected = []
      bytes = signal == :notices ? 14 : 0

      while (record = @queue.first) && record.signal == signal && selected.length < record_limit
        separator_bytes = selected.empty? ? 0 : 1
        break if !selected.empty? && bytes + separator_bytes + record.bytes > config.max_batch_bytes

        selected << @queue.shift
        bytes += separator_bytes + record.bytes
        @queue_bytes -= record.bytes
      end

      selected
    end

    def deliver_batch(batch)
      signal = batch.first.signal
      payload = signal == :notices ? { notices: batch.map(&:payload) } : batch.first.payload
      config = UpdogRubyClient.configuration
      transport = config.transport || HttpTransport.new(
        open_timeout: config.open_timeout,
        read_timeout: config.read_timeout,
        retries: config.retries,
        on_retry: method(:record_retry)
      )

      transport.post_json(
        signal == :notices ? config.notices_url : config.deployments_url,
        payload,
        headers: {
          "X-API-Key" => config.api_key.to_s,
          "X-Updog-Request-ID" => "req_#{SecureRandom.uuid}"
        }
      )
      :ok
    rescue Transport::PayloadTooLarge
      return :record_too_large if batch.length == 1

      midpoint = batch.length / 2
      left = deliver_batch(batch.take(midpoint))
      right = deliver_batch(batch.drop(midpoint))
      left == :ok && right == :ok ? :ok : :split_delivery_failed
    rescue Transport::PermanentError
      :permanent_http_error
    rescue Transport::DeliveryError, StandardError
      :retries_exhausted
    end

    def normalize(signal, payload)
      config = UpdogRubyClient.configuration
      timestamp_key = signal == :notices ? :occurred_at : :deployed_at

      payload.merge(
        event_id: payload[:event_id] || payload["event_id"] || "evt_#{SecureRandom.uuid}",
        timestamp_key => payload[timestamp_key] || payload[timestamp_key.to_s] || Time.now.utc.iso8601,
        service: payload[:service] || payload["service"] || config.service,
        environment: payload[:environment] || payload["environment"] || config.environment,
        release: payload[:release] || payload["release"] || config.release,
        hostname: payload[:hostname] || payload["hostname"] || Socket.gethostname,
        sdk_name: "updog_ruby_client",
        sdk_version: VERSION
      )
    end

    def priority(signal)
      signal == :notices ? 100 : 90
    end

    def make_room(record, config)
      while !room?(record, config)
        index = @queue.index { |queued| queued.priority < record.priority }
        break unless index

        removed = @queue.delete_at(index)
        @queue_bytes -= removed.bytes
        @stats[:dropped][:evicted_for_priority] += 1
      end
    end

    def room?(record, config)
      @queue.length < config.max_queue_records && @queue_bytes + record.bytes <= config.max_queue_bytes
    end

    def batch_ready?(config)
      @queue.length >= config.max_batch_records || @queue_bytes >= config.max_batch_bytes
    end

    def record_retry
      @mutex.synchronize { @stats[:retried] += 1 }
    end

    def drop(reason)
      @stats[:dropped][reason] += 1
      :ok
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
