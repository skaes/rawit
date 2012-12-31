require 'socket'

module Rawit
  class Notifier
    include Logging

    def initialize(service, event, details)
      @service = service
      @event = event
      @details = details
    end

    def run
      context = ZMQ::Context.new(1)
      socket = context.socket(ZMQ::PUSH)
      socket.setsockopt(ZMQ::LINGER, 1000)
      socket.connect("tcp://#{Rawit::server}:5555")
      data = message.to_json
      if socket.send_string(data) < 0
        logger.error "could not send message: #{ZMQ::Util.error_string}"
      end
      socket.close
      context.terminate
    end

    def message
      msg = {
        :time =>Time.now.to_s, :host => Socket.gethostname,
        :service => @service, :event => @event, :message => @details
      }
      logger.info "notification: #{msg.inspect}"
      msg
    end

  end
end
