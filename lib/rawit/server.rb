module Rawit
  require "sinatra/base"
  require "haml"
  require "tilt/haml"

  class Server < Sinatra::Base
    include Logging

    set :public_folder, "#{Rawit::ROOT}/public"
    set :views, "#{Rawit::ROOT}/views"
    set :haml, :format => :html5

    configure do
      @@manager = Rawit::Manager.new.run
    end

    helpers do
      def possible_actions(service)
        status, wants = service.values_at('status', 'wants')
        case status
        when 'run','up'
          %w(stop restart)
        when 'down','exited'
          wants == 'up' ? %w(sysadmin) : %w(start)
        when 'paused'
          %w(unpause)
        else
          []
        end
      end

      def needs_warning?(service)
        status, wants = service.values_at('status', 'wants')
        status == "down" && wants == "up"
      end

      def formatted_time(seconds)
        return seconds if seconds.is_a?(String)
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
      redirect '/hosts', 302
    end

    get '/processes' do
      @processes = @@manager.services.all
      @selected_tab = '#processes'
      haml :processes, :layout => !request.xhr?
    end

    get '/hosts' do
      @hosts = @@manager.services.host_summary
      @selected_tab = '#hosts'
      haml :hosts, :layout => !request.xhr?
    end

    get '/services' do
      @services = @@manager.services.service_summary
      @selected_tab = '#services'
      haml :services, :layout => !request.xhr?
    end

    get '/notifications' do
      @selected_tab = '#notifications'
      haml :notifications, :layout => !request.xhr?
    end

    post %r{/service/(stop|start|restart|unpause)} do
      pass unless request.xhr?
      action = params[:captures].first
      request.body.rewind  # in case someone already read it
      data = JSON.parse request.body.read
      host = data.delete("host")
      service = data.delete("service")
      msg = "Request to #{action} service #{service} on #{host} accepted"
      logger.info msg
      host.split(/ +/).each do |h|
        @@manager.send_command(h, {"service" => service, "action" => action}.to_json)
      end
      [202, msg]
    end
  end

end
