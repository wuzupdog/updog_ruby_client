module UpdogRubyClient
  module Backtrace
    module_function

    def format(backtrace)
      Array(backtrace).map do |line|
        {
          file: line.to_s.split(":", 3)[0],
          line: extract_line_number(line),
          method: extract_method(line),
          raw: line.to_s
        }
      end
    end

    def extract_line_number(line)
      parts = line.to_s.split(":")
      Integer(parts[1], exception: false)
    end

    def extract_method(line)
      match = line.to_s.match(/`([^']+)'/)
      match && match[1]
    end
  end
end
