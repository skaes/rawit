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
      socket.setsockopt(ZMQ::LINGER, 3000)
      socket.connect("tcp://#{Rawit::server}:9000")
      socket.send_string(message.to_json, ZMQ::NOBLOCK)
      socket.close
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
