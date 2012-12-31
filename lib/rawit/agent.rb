module Rawit
  class Agent
    include Logging

    def initialize
      @collector = Collector.new
    end

    def run
      EM.run do
        trap_signals
        @context = EM::ZeroMQ::Context.new(1)
        setup_outbound
        setup_inbound
        logger.info "rawit agent running"
      end
    end

    def message
      msg = @collector.status.to_json
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
        m.close
        action = j["action"]
        service = j["service"]
        @collector.execute(action, service)
      end
    end

    private
    def setup_outbound
      @outbound = @context.socket(ZMQ::PUSH)
      if defined?(ZMQ::SNDHWM)
        @outbound.setsockopt(ZMQ::SNDHWM, 1)
      else
        @outbound.setsockopt(ZMQ::HWM, 1)
      end
      @outbound.setsockopt(ZMQ::LINGER, 0)
      @outbound.connect("tcp://#{Rawit.server}:#{Rawit.agent_port}")
      EM.add_periodic_timer(2) do
        begin
          if @outbound.send_msg(message)
            logger.debug "sent service status"
          else
            logger.error "sending status failed"
          end
        rescue Exception
          $stderr.puts $!.inspect
        end
      end
    end

    def setup_inbound
      @inbound = @context.socket(ZMQ::PULL)
      @inbound.setsockopt(ZMQ::LINGER, 1000) # millicesonds
      @inbound.bind("tcp://0.0.0.0:#{Rawit.commands_port}")
      @inbound.on(:message){|*messages| messages_received(messages)}
    end

  end
end
