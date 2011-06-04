require 'optparse'

module Rawit
  module Commands
    class Manager
      def self.execute
        opts = OptionParser.new
        opts.banner = "Usage: rawit agent [options]"
        opts.separator ""
        opts.separator "options:"

        opts.on("-v", "--verbose", "Set log level to DEBUG") do
          require 'rawit'
          Rawit::logger.level = Logger::DEBUG
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.parse!(ARGV)

        require 'rawit'
        Rawit::Manager.new.run
      end
    end
  end
end
