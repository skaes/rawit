module Rawit
  require "sinatra/base"

  class Server < Sinatra::Base
    include Logging

    set :public, "#{Rawit::ROOT}/public"
    set :views, "#{Rawit::ROOT}/views"
    set :haml, :format => :html5

    configure do
      @@manager = Rawit::Manager.new.run
    end

    helpers do
      def possible_actions(status, wants)
        case status
        when 'run'
          %w(stop restart)
        when 'down'
          wants == 'up' ? %w(sysadmin) : %w(start)
        end
      end
    end

    get '/' do
      @services = @@manager.services
      haml :index
    end

    post %r{/service/(stop|start|restart)} do
      pass unless request.xhr?
      action = params[:captures].first
      request.body.rewind  # in case someone already read it
      data = JSON.parse request.body.read
      host = data.delete("host")
      service = data.delete("service")
      msg = "Request to #{action} service #{service} on #{host} accepted"
      logger.info msg
      @@manager.send_command(host, {"service" => service, "action" => action}.to_json)
      [202, msg]
    end
  end

end
