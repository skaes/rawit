require "json"
require "em-zeromq"

module Rawit
  class Manager
    include Logging

    class PullHandler
      attr_reader :received
      def on_readable(socket, messages)
        messages.each do |m|
          j = JSON.parse(m.copy_out_string)
          p j
        end
      end
    end

    def run
      EM.run do
        trap_signals
        @context = EM::ZeroMQ::Context.new(1)
        @socket = @context.bind( ZMQ::PULL, "tcp://127.0.0.1:9000", PullHandler.new)
        logger.info "rawit manager running"
      end
    end

    def trap_signals
      trap("INT"){ terminate }
      trap("TERM"){ terminate }
    end

    def terminate
      EM.stop_event_loop
    end

  end
end
