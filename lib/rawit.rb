begin
  require "zmq"
  require "active_support"
  require "active_support/core_ext"
rescue LoadError
  require "rubygems"
  require "zmqp"
  require "active_support"
  require "active_support/core_ext"
end

module Rawit

  $:.unshift(File.expand_path('..', __FILE__))

  # use ruby's autoload mechanism for loading rawit classes
  lib_dir = File.expand_path(File.dirname(__FILE__) + '/rawit/')
  Dir["#{lib_dir}/*.rb"].each do |libfile|
    autoload File.basename(libfile)[/^(.*)\.rb$/, 1].classify, libfile
  end

  mattr_accessor :logger
  self.logger = Logger.new($stdout)

end
