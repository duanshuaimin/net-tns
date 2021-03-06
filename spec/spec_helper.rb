begin
  require "coveralls"
  Coveralls.wear!
rescue LoadError
end

require "rspec"
require "rspec/its"

RSpec::Matchers.define :eql_binary_string do |expected|
  match do |actual|
    actual = actual.to_binary_s if actual.respond_to?(:to_binary_s)
    expected = expected.to_binary_s if expected.respond_to?(:to_binary_s)
    actual == expected
  end

  failure_message do |actual|
    actual = actual.to_binary_s if actual.respond_to?(:to_binary_s)
    expected = expected.to_binary_s if expected.respond_to?(:to_binary_s)
    [
      "  Expected: \"#{expected.tns_hexify}\"",
      "       Got: \"#{actual.tns_hexify}\"",
      # "  Expected: \"#{expected}\"",
      # "       Got: \"#{actual}\"",
    ].join("\n")
  end

  failure_message_when_negated do |actual|
    "expected that the binary strings wouldn't match"
  end
end

module SpecHelpers
  class FakeSocket
    class SocketClosed < StandardError; end
    class NoMoreData < StandardError; end

    def initialize( host="127.0.0.1", port=1521 )
      @dst_host = host
      @dst_port = port
      @io_out = StringIO.new()
      @io_in = StringIO.new()
      @closed = false
    end

    def peeraddr
      return [nil, @dst_port, nil, @dst_host]
    end

    # Socket-like functions
    def close
      @closed = true
    end

    def closed?
      @closed == true
    end

    def write(foo)
      raise SocketClosed if closed?

      @io_out.write(foo)
    end

    def read(length)
      data = @io_in.read(length)
      raise NoMoreData if data.nil?
      return data
    end


    # Administrative functions
    def _written_data
      return @io_out.string.dup.force_encoding("BINARY")
    end

    def _clear_written_data!
      @io_out = StringIO.new()
    end

    def _queue_response(data)
      data = data.to_binary_s if data.respond_to?(:to_binary_s)
      @io_in.string << data.force_encoding("BINARY")
    end

    def _has_unread_data?
      return ! @io_in.eof?
    end
  end
end
