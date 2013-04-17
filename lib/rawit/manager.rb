require 'em-websocket'

module Rawit
  class Manager
    include Logging

    attr_reader :services

    def initialize
      logger.info "initializing rawit manager"
      @services = Rawit::Services.new
      @outbound_connections = {}
      setup_notifier
    end

    def setup_notifier
      @sockets = []
      EventMachine::WebSocket.start(:host => "0.0.0.0", :port => Rawit.websockets_port) do |ws|
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

        ws.onerror do |error|
          logger.error error.inspect
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
        m.close
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

    def setup_inbound
      @inbound = @context.socket(ZMQ::PULL)
      @inbound.bind("tcp://0.0.0.0:#{Rawit.agent_port}")
      @inbound.on(:message){|*messages| messages_received(messages)}
    end

    def setup_outbound(host)
      @outbound_connections[host] ||=
        begin
          socket = @context.socket(ZMQ::PUSH)
          socket.setsockopt(ZMQ::SNDHWM, 1)
          socket.setsockopt(ZMQ::LINGER, 1000) # milliseconds
          # ip = IPSocket.getaddress host
          socket.connect("tcp://#{host}:#{Rawit.commands_port}")
          socket
        end
    end

    def send_command(host, message)
      socket = setup_outbound(host)
      if socket.send_msg(message)
        logger.debug "sent service command. dest=#{host}"
      else
        logger.error "sending service command failed. dest=#{host}"
      end
    end

  end
end
