require 'bundler/setup'
Bundler::GemHelper.install_tasks

desc "start the development environment"
task :start do
  my_dir = File.expand_path('..', __FILE__)
  monit_file = "#{my_dir}/etc/monitrc"
  procfile = "#{my_dir}/Procfile"
  verbose = ENV['debug'] == '1' ? " -v" : ""
  File.open(procfile, "w") do |f|
    f.puts "agent: bundle exec rawit agent#{verbose}"
    # f.puts "manager: bundle exec rawit manager#{verbose}"
    f.puts "server: bundle exec rawit server#{verbose}"
    f.puts "services: runsvdir #{my_dir}/services log:...................................................................."
  end
  #puts "starting monit"
  #system "sudo chown root #{monit_file}"
  #system "sudo chmod 700 #{monit_file}"
  #system "sudo monit -c #{monit_file}"
  system "foreman start"
  #puts "stopping monit"
  #system "sudo monit -c #{monit_file} quit"
  #system "sudo chown #{ENV['USER']} #{monit_file}"
end

task :default => :start
