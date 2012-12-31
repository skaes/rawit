require 'optparse'
require 'fileutils'

module Rawit
  module Commands
    class Notifier
      def self.execute
        opts = OptionParser.new
        opts.banner = "Usage: rawit notifier [options] event d1 ... dn"
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
        service = FileUtils.pwd
        event = ARGV.shift
        Rawit::Notifier.new(service, event, ARGV.join(' ')).run
      end
    end
  end
end
