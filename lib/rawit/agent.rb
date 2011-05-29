module Rawit
  class Agent
    include Logging

    def initialize
      logger.info "Opening connection for WRITE"
      @context = ZMQ::Context.new(1)
      @outbound = @context.socket(ZMQ::PUSH)
      @outbound.setsockopt(ZMQ::HWM, 1)
      @outbound.setsockopt(ZMQ::LINGER, 0)
      @outbound.connect("tcp://127.0.0.1:9000")
    end

    def run
      logger.info "rawit agent running"
      trap_signals
      loop do
        logger.error "sending failed" unless @outbound.send(message, ZMQ::NOBLOCK)
        sleep 1
      end
    end

    def message
      msg = Collector.new.status.to_json
      logger.info msg.inspect
      msg
    end

    def trap_signals
      trap("INT"){ terminate }
      trap("TERM"){ terminate }
    end

    def terminate
      @outbound.close if @outbound
      @context.close if @context
      exit
    end
  end
end
