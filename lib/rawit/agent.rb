module Rawit
  class Agent
    include Logging

    def run
      EM.run do
        trap_signals
        @context = EM::ZeroMQ::Context.new(1)
        setup_outbound
        setup_inbound
        logger.info "rawit agent running"
      end
    end

    def manager_hostname
      Socket.gethostname
    end

    def message
      msg = Collector.new.status.to_json
      logger.debug "sending #{msg.inspect}"
      msg
    end

    def trap_signals
      trap("INT"){ terminate }
      trap("TERM"){ terminate }
    end

    def terminate
      EM.stop_event_loop
    end

    def messages_received(messages)
      messages.each do |m|
        j = JSON.parse(m.copy_out_string)
        action = j["action"]
        service = j["service"]
        cmd = "sv #{action} #{service}"
        logger.info `#{cmd}`
      end
    end

    private
    def setup_outbound
      @outbound = @context.socket(ZMQ::PUSH)
      @outbound.setsockopt(ZMQ::HWM, 1)
      @outbound.setsockopt(ZMQ::LINGER, 0)
      @outbound_connection = @context.connect(@outbound, "tcp://#{manager_hostname}:9000")
      EM.add_periodic_timer(2) do
        if @outbound_connection.socket.send_string(message, ZMQ::NOBLOCK)
          logger.info "sent service status"
        else
          logger.error "sending status failed"
        end
      end
    end

    class PullHandler
      def initialize(agent)
        @agent = agent
      end
      def on_readable(socket, messages)
        @agent.messages_received(messages)
      end
    end

    def setup_inbound
      @inbound = @context.socket(ZMQ::PULL)
      @inbound.setsockopt(ZMQ::LINGER, 1000) # millicesonds
      @inbound_connection = @context.bind(@inbound, "tcp://0.0.0.0:9001", PullHandler.new(self))
    end

  end
end
