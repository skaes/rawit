require "json"

module Rawit
  class Manager
    include Logging

    def initialize
      logger.info "Opening connection for READ"
      @context = ZMQ::Context.new(1)
      @inbound = @context.socket(ZMQ::PULL)
      @inbound.bind("tcp://127.0.0.1:9000")
    end

    def run
      logger.info "rawit manager running"
      trap_signals
      loop do
        data = @inbound.recv
        j = JSON.parse(data)
        p j
      end
    end

    def trap_signals
      trap("INT"){ terminate }
      trap("TERM"){ terminate }
    end

    def terminate
      @inbound.close if @inbound
      @context.close if @context
      exit
    end

  end
end
