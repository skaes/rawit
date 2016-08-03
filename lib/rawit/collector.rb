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
      {:host => hostname, :services => runit_status + monit_status + docker_status}
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


    # NETWORK ID                                                         NAME                   DRIVER              SCOPE
    # e8f21ef52525d159659cf33e58db7360a07b776fe0e89fda3559aca6ed7a269b   beetle_default         bridge              local
    # f5693cbf79f5ae54328ecf6ba3e4774c098987357a36563b8240e1ac2d3d3bb9   bridge                 bridge              local
    # adf73a0f039cd60531a0dee89493d32ebde9613e2c0268dd3e27d3b54102edd9   host                   host                local
    # ae61976c952c88c79b716cf4cbe3f5da423fd1646076931f1612d2ccc9c74ab1   logjamdocker_default   bridge              local
    # d19984ce4411b5005e3581d58a2c9438772f6c781ef5eb5c750e078632bd24a7   none                   null                local
    # 53084365a37b08c79eea8bf21e51821ef5d019be4ff5420912faebbbdd9350e0   rawit_default          bridge              local
    # 1ce1ed0a3cf658bcfd4f0ae5f55026ac07ba7b3bb0a634256b671fd18f096508   timebandits_default    bridge              local
    def docker_network_prefixes
      networks = `docker network ls`.chomp.split("\n")[1..-1]
      networks.map{|l| l.split[1].sub(/bridge|host|none|_default\z/,'')}.reject(&:empty?)
    end

    def docker_services
      `docker-compose config --services 2>&1`.chomp.split("\n")
    end

    def docker_containers
      prefixes = docker_network_prefixes
      uptime = docker_uptime
      `docker-compose ps`.chomp.split("\n")[2..-1].map do |l|
        name = l.split.first
        since = uptime[name]
        name.sub!(/_\d+\z/,'')
        prefixes.each{|p| name.sub!(/\A#{p}_/,'')}
        status = l =~ / (Up)|(Paused)|(Exit) \d+/ && ($1||$2||$3).downcase
        [name, status, since]
      end
    end

    def convert_docker_status(status)
      case status
      when "up" then "up"
      when "exit" then "exited"
      when "paused" then "paused"
      end
    end

    def docker_uptime
      `docker ps -a --format '{{.Names}}:{{.Status}}'`.chomp.split("\n").each_with_object({}) do |l,h|
        name, since = l.split(':')
        h[name] = since.gsub(/ago|Up|Exited \(\d+\)/,'').strip
      end
    end

    def docker_status
      docker_containers.map do |name, status, uptime|
        {
          :type => :docker,
          :name => name,
          :status => convert_docker_status(status),
          :since => uptime
        }
      end
    end

    KNOWN_ACTIONS = %w(start stop restart unpause)

    def execute(action, services)
      unless KNOWN_ACTIONS.include?(action.to_s)
        logger.error "unknown action: #{action}"
        return
      end
      sv_action = action == "restart" ? "force-restart" : action
      paths = services.split(/ +/)
      sv_owned = paths.select{|s| s =~ %r{/}}
      monit_owned = []
      docker_owned = paths - sv_owned
      sv_owned.each do |path|
        cmd = "sv -w 10 #{sv_action} #{path}"
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
      unless docker_owned.blank?
        cmd = "docker-compose #{action} #{docker_owned.join(' ')}"
        logger.info cmd
        logger.info `#{cmd}`
      end
    end

  end
end
