module Rawit
  class Manager
    include Logging

    attr_reader :services

    def initialize
      @services = {}
    end

    class PullHandler
      def initialize(manager)
        @manager = manager
      end
      def on_readable(socket, messages)
        @manager.messages_received(messages)
      end
    end

    def messages_received(messages)
      logger.debug "received service data"
      messages.each do |m|
        j = JSON.parse(m.copy_out_string)
        j.each do |entry|
          host = entry.delete("host")
          service = entry.delete("name")
          @services[[host,service]] = entry
        end
      end
    end

    def run
      trap_signals
      @context = EM::ZeroMQ::Context.new(1)
      @socket = @context.socket(ZMQ::PULL)
      @connection = @context.bind(@socket, "tcp://127.0.0.1:9000", PullHandler.new(self))
      logger.info "rawit manager running"
      self
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
