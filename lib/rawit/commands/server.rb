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
        require 'rack'
        EM.run do
          app = Rack::Builder.app do
            map '/' do
              run Rawit::Server.new
            end
          end

          Rack::Server.start(:app => app, :server => 'thin', :Host => "0.0.0.0", :Port => 4567)
        end
      end
    end
  end
end
