module Rawit
  require "sinatra/base"

  class Server < Sinatra::Base

    configure do
      @@manager = Rawit::Manager.new.run
    end

    include Logging

    set :public, "#{Rawit::ROOT}/public"
    set :views, "#{Rawit::ROOT}/views"
    set :haml, :format => :html5

    get '/' do
      @services = @@manager.services
      haml :index
    end
  end

end
