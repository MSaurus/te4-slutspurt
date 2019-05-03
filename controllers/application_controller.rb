require 'sinatra/base'
require 'slim'

# The base class for all controller
class ApplicationController < Sinatra::Base
  enable :logging
  set :views, File.expand_path('../views', __dir__)
end
