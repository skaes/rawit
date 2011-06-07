require 'bundler'
Bundler::GemHelper.install_tasks

task :start do
  my_dir = File.expand_path('..', __FILE__)
  procfile = "#{my_dir}/Procfile"
  puts my_dir
  File.open(procfile, "w") do |f|
    f.puts "services: runsvdir #{my_dir}/services log:...................................................................."
    f.puts "agent: bundle exec rawit agent -v"
    f.puts "server: bundle exec rawit server -v"
  end
  exec "foreman start"
end

task :default => :start
