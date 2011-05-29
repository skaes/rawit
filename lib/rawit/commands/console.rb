require 'optparse'

module Rawit
  module Commands
    class Console
      def self.execute
        options = { }
        OptionParser.new do |opts|
          opts.banner = "Usage: rawit console [options]"

          opts.on("--debugger", 'Enable ruby-debugging for the console.') { |v| options[:debugger] = v }

          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
          opts.parse!(ARGV)
        end

        libs =  " -r irb/completion"
        libs << %( -r ubygems)
        libs << %( -r #{File.expand_path("../../../../lib/rawit.rb",__FILE__)})

        if options[:debugger]
          begin
            require 'ruby-debug'
            libs << " -r ruby-debug"
            puts "=> Debugger enabled"
          rescue Exception
            puts "You need to install ruby-debug to run the console in debugging mode. With gems, use 'gem install ruby-debug'"
            exit
          end
        end

        exec "irb #{libs} --simple-prompt"
      end
    end
  end
end
