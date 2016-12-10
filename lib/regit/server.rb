require 'sinatra/base'

module Regit
  class WebApp < Sinatra::Base
    get '/' do
      'Hello world!'
    end
    
  end
end