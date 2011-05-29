module Rawit
  class Manager
    include Logging

    def run
      loop do
        logger.info "manager running"
        sleep 1
      end
    end
  end
end
