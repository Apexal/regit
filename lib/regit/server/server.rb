require 'sinatra/base'

module Regit
  class WebApp < Sinatra::Base
    set :bind, '45.55.205.134'

    get '/' do
      'Hello world'
    end
  end
end