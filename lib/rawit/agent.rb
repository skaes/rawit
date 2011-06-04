module Rawit
  class Agent
    include Logging

    def run
      EM.run do
        trap_signals
        @context = EM::ZeroMQ::Context.new(1)
        @socket = @context.socket(ZMQ::PUSH)
        @socket.setsockopt(ZMQ::HWM, 1)
        @socket.setsockopt(ZMQ::LINGER, 0)
        @connection = @context.connect(@socket, "tcp://127.0.0.1:9000")
        EM.add_periodic_timer(1) do
          if @connection.socket.send_string(message, ZMQ::NOBLOCK)
            logger.info "sent service status"
          else
            logger.error "sending status failed"
          end
        end
        logger.info "rawit agent running"
      end
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

  end
end
