module Rawit
  class Services
    include Logging

    def initialize
      @services = {}
    end

    def all
      @services
    end

    def update(services)
      @services[services["host"]] = services["services"]
    end

    def host_summary
      @services.inject({}) do |hosts, (host, services)|
        num_up   = services.select{|i| i["status"] == "run" || i["status"] == "up"}.size
        num_down = services.select{|i| i["status"] == "down" || i["status"] == "exited" || i["status"] == "paused"}.size
        service_names = services.map{|i| i["name"]}
        hosts[host] = [num_up, num_down, service_names]
        hosts
      end
    end

    def service_summary
      hash = Hash.new{|h, k| h[k] = {"up" => 0, "down" => 0, "hosts" => []}}
      @services.each do |host, services|
        services.each do |service|
          si = hash[service["name"]]
          si["hosts"] << host
          si["up"] += 1 if service["status"] == "run" || service["status"] == "up"
          si["down"] += 1 if service["status"] == "down" || service["status"] == "exited" || service["status"] == "paused"
        end
      end
      hash
    end

  end
end
