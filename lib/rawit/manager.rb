module Rawit
  class Manager
    include Logging

    attr_reader :services

    def initialize
      @services = Rawit::Services.new
      @outbound_connections = {}
    end

    def messages_received(messages)
      logger.debug "received service data"
      messages.each do |m|
        j = JSON.parse(m.copy_out_string)
        @services.update j
      end
    end

    def run
      trap_signals
      @context = EM::ZeroMQ::Context.new(1)
      setup_inbound
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
      @inbound_connection = @context.bind(@inbound, "tcp://0.0.0.0:9000", PullHandler.new(self))
    end

    def setup_outbound(host)
      @outbound_connections[host] ||=
        begin
          socket = @context.socket(ZMQ::PUSH)
          socket.setsockopt(ZMQ::HWM, 1)
          socket.setsockopt(ZMQ::LINGER, 1000) # milliseconds
          # ip = IPSocket.getaddress host
          @context.connect(socket, "tcp://#{host}:9001")
        end
    end

    def send_command(host, message)
      connection = setup_outbound(host)
      if connection.socket.send_string(message, ZMQ::NOBLOCK)
        logger.info "sent service command"
      else
        logger.error "sending service command failed"
      end
    end

  end
end
