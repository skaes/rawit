require 'active_support'
require 'active_support/core_ext'

module Rawit
  module Commands
    # invokes given command by instantiating an appropriate command class
    def self.execute(command)
      if commands.include? command
        require File.expand_path("../commands/#{command}", __FILE__)
        "Rawit::Commands::#{command.classify}".constantize.execute
      else
        puts "\nCommand #{command} not known\n" if command
        puts "Available commands are:"
        puts
        commands.each {|c| puts "\t #{c}"}
        puts
        exit 1
      end
    end

    private
    def self.commands
      commands_dir = File.expand_path('../commands', __FILE__)
      Dir[commands_dir + '/*.rb'].map {|f| File.basename(f)[0..-4]}
    end
  end
end

Rawit::Commands.execute(ARGV.shift)
