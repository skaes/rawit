module Rawit
  module Logging
    def logger
      @logger ||= Rawit::logger
    end
  end
end
