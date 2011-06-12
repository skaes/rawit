require 'bundler'
Bundler::GemHelper.install_tasks

task :start do
  my_dir = File.expand_path('..', __FILE__)
  procfile = "#{my_dir}/Procfile"
  verbose = ENV['debug'] == '1' ? " -v" : ""
  File.open(procfile, "w") do |f|
    f.puts "agent: bundle exec rawit agent#{verbose}"
    f.puts "server: bundle exec rawit server#{verbose}"
    f.puts "services: runsvdir #{my_dir}/services log:...................................................................."
  end
  exec "foreman start"
end

task :default => :start
