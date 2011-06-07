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
      def possible_actions(service)
        status, wants = service.values_at('status', 'wants')
        case status
        when 'run'
          %w(stop restart)
        when 'down'
          wants == 'up' ? %w(sysadmin) : %w(start)
        end
      end

      def needs_warning?(service)
        status, wants = service.values_at('status', 'wants')
        status == "down" && wants == "up"
      end

      def formatted_time(seconds)
        days, hrs = seconds.to_i.divmod(3600*24)
        hrs, mins = hrs.divmod(3600)
        mins, secs = mins.divmod(60)
        vals = [days, hrs, mins, secs]
        vals.shift while vals[0] == 0
        vals = [0] if vals.empty?
        vals.map!{|v| sprintf "%02d", v}
        vals.first.gsub!(/^0(\d)/,'\1')
        "#{vals.join(':')}s"
      end
    end

    get '/' do
      haml :index
    end

    get '/services' do
      @services = @@manager.services
      haml :services, :layout => false
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
