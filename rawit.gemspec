# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rawit/version"

Gem::Specification.new do |s|
  s.name        = "rawit"
  s.version     = Rawit::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stefan Kaes"]
  s.email       = ["skaes@railsexpress.de"]
  s.homepage    = ""
  s.summary     = %q{Service Management System based on runit}
  s.description = %q{Secret Sauce}

  s.rubyforge_project = "rawit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.specification_version = 3
  s.add_runtime_dependency("activesupport",  [">= 4.1.1"])
  s.add_runtime_dependency("i18n",           ["~> 0.6"])
  s.add_runtime_dependency("json",           ["~> 1.8"])
  s.add_runtime_dependency("em-zeromq",      [">= 0.5.0"])
  s.add_runtime_dependency("em-websocket",   [">= 0.5.1"])

  s.add_development_dependency("rake",     [">= 0"])
  s.add_development_dependency("wirble",     [">= 0"])
  s.add_development_dependency("daemons",    [">= 0"])

end
