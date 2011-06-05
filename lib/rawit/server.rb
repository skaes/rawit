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
      def possible_actions(status)
        case status
        when 'run'
          %w(stop restart)
        else
          %w(start)
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
      host = data["host"]
      service = data["service"]
      logger.info "#{action}: #{data.inspect}"
      [202, "Request to #{action} service #{service} on #{host} accepted"]
    end
  end

end
