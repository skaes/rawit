module Rawit
  class Collector
    def initialize

    end

    def processes
      `ps -e -o 'pid,command' | egrep -e 'runsvdir|runsv' | egrep -v 'grep|daemondo'`.chomp.split("\n").
        map{|s| s =~ /^\s*(\d+)\s*(.+)$/ && [$1.to_i,$2]}.compact
    end

    def directories
      processes.map{|_,s| s =~ /^\S+runsvdir\s+(-P)?(\S+)/ && $2}.compact
    end

    def services
      patterns = directories.map{|d| d += '/*/run'}
      Dir[*patterns].map{|f| f.gsub(%r{/run,''})}
    end

    def status
      result = []
      unless services.empty?
        `sv status #{services}`.chomp.split("\n").each do |l|
          service, logger = l.split(/;/)
          if service =~ /^(.+): (.+): \(pid: (\d+)\) (\d+)s/
            result << {:status => $1, :name => $2, :pid => $3.to_i, :time => $4.to_i}
          end
        end
      end
      result
    end
  end
end
