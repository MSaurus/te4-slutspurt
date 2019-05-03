require 'sinatra/base'

Dir.glob('./{models,helpers,controllers}/*.rb').each { |file| require file }

map('/') { run AppController }
map('/users') { run UserController }
