require 'socket'

module Rawit
  class Collector
    include Logging

    def initialize
    end

    def hostname
      Socket.gethostname
    end

    def processes
      `ps -e -o 'pid,command' | egrep -e 'runsvdir|runsv' | egrep -v 'grep|daemondo'`.chomp.split("\n").
        map{|s| s =~ /^\s*(\d+)\s*(.+)$/ && [$1.to_i,$2]}.compact
    end

    def directories
      processes.map{|_,s| s =~ /^\S+runsvdir\s+(-P)?(\S+)/ && $2}.compact
    end

    def services
      patterns = directories.map{|d| d += '/*'}
      Dir[*patterns].to_a
    end

    def status
      result = []
      unless services.empty?
        `sv status #{services.join(' ')}`.chomp.split("\n").each do |l|
          logger.debug l
          service, logger = l.split(/;/)
          # run: /opt/local/var/service/test1: (pid 60957) 582s
          # down: /opt/local/var/service/test2: 240s, normally up
          if service =~ /^(run): (.+): \(pid (\d+)\) (\d+)s/
            result << {:host => hostname, :status => $1, :name => $2, :pid => $3.to_i, :time => $4.to_i}
          elsif service =~ /^(down): (.+): (\d+)s, normally (.*)(, wants (.*))?/
            result << {:host => hostname, :status => $1, :name => $2, :time => $3.to_i, :normally => $4, :wants => $6}
          end
        end
      end
      result
    end
  end
end
