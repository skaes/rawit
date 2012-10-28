require 'socket'

module Rawit
  class Collector
    include Logging

    def initialize
    end

    def hostname
      Socket.gethostname
    end

    def status
      {:host => hostname, :services => runit_status + monit_status}
    end

    def runit_status
      result = []
      unless runit_services.empty?
        `sv status #{runit_services.join(' ')}`.chomp.split("\n").each do |l|
          # logger.debug l
          service, logger = l.split(/;/)
          # run: /opt/local/var/service/test1: (pid 60957) 582s
          # down: /opt/local/var/service/test2: 240s, normally up
          if service =~ /^(run): (.+): \(pid (\d+)\) (\d+)s/
            result << {:type => "runit", :name => $2, :pid => $3.to_i, :status => $1, :since => $4.to_i}
          elsif service =~ /^(down): (.+): (\d+)s, normally (up|down)(, want (up|down))?/
            result << {:type => "runit", :name => $2, :status => $1, :since => $3.to_i, :normally => $4, :wants => $6}
          end
        end
      end
      result
    end

    def runit_services
      patterns = runsv_directories.map{|d| d += '/*'}
      Dir[*patterns].to_a
    end

    def runsv_directories
      runsv_processes.map{|_,s| s =~ /^\S*runsvdir\s+(-P\s)?(\S+)/ && $2}.compact
    end

    def runsv_processes
      `ps -e -o 'pid,command' | egrep -w -e 'runsvdir|runsv' | egrep -v 'grep|daemondo'`.chomp.split("\n").
        map{|s| s =~ /^\s*(\d+)\s*(.+)$/ && [$1.to_i,$2]}.compact
    end

    def monit_status
      result = []
      monit_processes.each do |_,c|
        str = `sudo #{c} status`
        result.concat(monit_parse(str.chomp))
      end
      result
    end

    def monit_processes
      # disabled for security reasons
      return []
      `ps -e -o 'pid,command' | egrep -w -e 'monit' | egrep -v 'grep|daemondo'`.chomp.split("\n").
        map{|s| s =~ /^\s*(\d+)\s*(.+)$/ && [$1.to_i,$2]}.compact
    end

    def monit_parse(str)
      res = []
      str.split(/\n\n/).each do |section|
        next unless section =~ /Process/
        res << parse_process_section(section)
      end
      res
    end

    def parse_process_section(e)
      res = {:type => "monit"}
      e.each_line do |line|
        case line
        when /^Process '(.*)'\s*$/
          res[:name] = $1
        when /^\s+status\s+(.*)\s*$/
          res[:status] = convert_monit_status($1.strip)
        when /^\s+pid\s+(.*)\s*$/
          res[:pid] = $1.to_i
        when /^\s+uptime\s+(.*)\s*$/
          res[:since] = convert_monit_uptime($1.strip)
        end
      end
      res
    end

    def convert_monit_status(s)
      case s
      when "running" then "run"
      else "down"
      end
    end

    def convert_monit_uptime(s)
      if s =~ /(\d+d)?\s*(\d+h)?\s*(\d+m)?\s*(\d+s)?/
        (($1.to_i * 24 + $2.to_i) * 60 + $3.to_i) *60 + $4.to_i
      else
        0
      end
    end

    KNOWN_ACTIONS = %w(start stop restart)

    def execute(action, service)
      unless KNOWN_ACTIONS.include?(action.to_s)
        logger.error "unknown action: #{action}"
        return
      end
      services = service.split(/ +/)
      sv_owned = services.select{|s| s =~ %r{/}}
      monit_owned = services - sv_owned
      sv_owned.each do |service|
        cmd = "sv -w 10 #{action} #{service}"
        logger.info `#{cmd}`
        sleep 1
      end
      unless monit_owned.blank?
        monit_processes.each do |_,m|
          monit_owned.each do |s|
            cmd = "sudo #{m} #{action} #{s}"
            logger.info `#{cmd}`
          end
        end
      end
    end

  end
end
