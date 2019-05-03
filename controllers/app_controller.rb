# Takes care of the main parts
class AppController < ApplicationController
  get '/' do
    slim :home
  end
end
