require 'optparse'

module Rawit
  module Commands
    class Server
      def self.execute
        opts = OptionParser.new
        opts.banner = "Usage: rawit server [options]"
        opts.separator ""
        opts.separator "options:"

        opts.on("-v", "--verbose", "Set log level to DEBUG") do |val|
          require 'rawit'
          Rawit::logger.level = Logger::DEBUG
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.parse!(ARGV)

        require 'rawit'
        EM.run { Rawit::Server.run! }
      end
    end
  end
end
