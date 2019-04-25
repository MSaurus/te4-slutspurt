require 'sinatra'
require 'pg'
require 'yaml'

begin
  config = YAML.load_file('config/database.yaml')
  conn = PG.connect host: config['host'],
                    dbname: config['dbname'],
                    user: config['user'],
                    password: config['password']
  puts conn.server_version
rescue PG::Error => e
  puts e.message
ensure
  conn.close if conn
end

get '/' do
  'Hello World'
end
