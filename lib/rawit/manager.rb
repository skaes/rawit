require 'em-websocket'

module Rawit
  class Manager
    include Logging

    attr_reader :services

    def initialize
      @services = Rawit::Services.new
      @outbound_connections = {}
      setup_notifier
    end

    def setup_notifier
      @sockets = []
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 9002) do |ws|
        ws.onopen do
          logger.info "web socket connection established: #{ws.object_id}"
          @sockets << ws
        end

        ws.onclose do
          logger.info "web socket connection closed: #{ws.object_id}"
          @sockets.delete(ws)
        end

        ws.onmessage do |msg|
          logger.info "web socket received message: #{ws.object_id}: #{msg}"
        end
      end
    end

    def notify(msg)
      @sockets.each do |ws|
        logger.debug "pushing to websocket: #{ws.object_id}: #{msg}"
        ws.send msg
      end
    end

    def messages_received(messages)
      messages.each do |m|
        data = m.copy_out_string
        logger.debug "received service data: #{data}"
        j = JSON.parse(data)
        if j["event"]
          notify([j].to_json)
        else
          @services.update j
        end
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
        logger.debug "sent service command"
      else
        logger.error "sending service command failed"
      end
    end

  end
end
