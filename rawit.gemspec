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
end
