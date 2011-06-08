begin
  require "em-zeromq"
rescue LoadError
  require "rubygems"
  require "em-zeromq"
end
require "json"
require "active_support"
require "active_support/core_ext"

module Rawit

  ROOT = File.expand_path('../..', __FILE__)

  $:.unshift("#{ROOT}/lib")

  # use ruby's autoload mechanism for loading rawit classes
  lib_dir = File.expand_path(File.dirname(__FILE__) + '/rawit/')
  Dir["#{lib_dir}/*.rb"].each do |libfile|
    const = File.basename(libfile)[/^(.*)\.rb$/, 1].capitalize
    # puts "autoload #{const}, #{libfile}"
    autoload const, libfile
  end

  mattr_accessor :logger
  self.logger = Logger.new($stdout)
  self.logger.level = Logger::INFO

  mattr_accessor :server
  self.server = "127.0.0.1"

end
