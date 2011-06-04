module Rawit
  require "sinatra/base"

  class Server < Sinatra::Base

    configure do
      @@manager = Rawit::Manager.new.run
    end

    include Logging

    get '/' do
      result = "<table>"
      result << "<tr><th>Host</th><th>Service</th><th>Status</th><th>Pid</th><th>Since</th><th>Normally</th></tr>"
      @@manager.services.each do |(host, service), e|
        result << "<tr><td>#{host}</td><td>#{service}</td><td>#{e["status"]}</td><td>#{e["pid"]}</td>"
        result << "<td>#{e["time"]}</td><td>#{e["normally"]}</td></tr>"
      end
      result << "</table>"
    end
  end

end
