require "ffi-rzmq"
require "em-zeromq"
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
  $stdout.sync = true
  self.logger.level = Logger::INFO

  mattr_accessor :server
  self.server = "127.0.0.1"

  mattr_accessor :base_port
  self.base_port = 9720
  # 9701-9746 are unassigned
  # don't forget to change rawitXXX.js when changing the base_port

  def self.agent_port; base_port; end
  def self.commands_port; base_port + 1; end
  def self.websockets_port; base_port + 2; end

end
