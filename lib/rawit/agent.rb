module Rawit
  class Agent
    include Logging

    def run
      loop do
        logger.info "agent running"
        sleep 1
      end
    end
  end
end
