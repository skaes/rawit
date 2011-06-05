module Rawit
  class Manager
    include Logging

    attr_reader :services

    def initialize
      @services = {}
    end

    def messages_received(messages)
      logger.debug "received service data"
      messages.each do |m|
        j = JSON.parse(m.copy_out_string)
        @services[j["host"]] = j["services"]
      end
    end

    def run
      trap_signals
      @context = EM::ZeroMQ::Context.new(1)
      setup_inbound
      setup_outbound
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

    class PullHandler
      def initialize(manager)
        @manager = manager
      end
      def on_readable(socket, messages)
        @manager.messages_received(messages)
      end
    end

    def setup_inbound
      @inbound = @context.socket(ZMQ::PULL)
      @inbound_connection = @context.bind(@inbound, "tcp://127.0.0.1:9000", PullHandler.new(self))
    end

    def setup_outbound
      @outbound = @context.socket(ZMQ::PUSH)
      @outbound.setsockopt(ZMQ::HWM, 1)
      @outbound.setsockopt(ZMQ::LINGER, 0)
      @outbound_connection = @context.connect(@outbound, "tcp://127.0.0.1:9001")
    end

    def send_command(message)
      if @outbound_connection.socket.send_string(message, ZMQ::NOBLOCK)
        logger.info "sent service command"
      else
        logger.error "sending service command failed"
      end
    end

  end
end
