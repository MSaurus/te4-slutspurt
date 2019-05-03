require 'pg'
require 'yaml'
require 'byebug'

# Takes care of the user part of the application
class UserController < ApplicationController
  before do
    config = YAML.load_file('config/database.yaml')
    @conn = PG.connect host: config['host'],
                       dbname: config['dbname'],
                       user: config['user'],
                       password: config['password']
  end

  get '/' do
    begin
      users = @conn.exec 'SELECT * FROM "user"'
      slim :'users/index', locals: { users: users }
    rescue PG::Error => e
      puts e.message
    ensure
      users.clear if users
      @conn.close if @conn
    end
  end

  get '/new' do
    slim :'users/new'
  end

  post '/new' do
    begin
      @conn.transaction do |conn|
        conn.prepare 'user_insert',
                     'INSERT INTO "user" (first_name, last_name)
                      VALUES ($1, $2) returning *'
        conn.prepare 'credential_insert',
                     'INSERT INTO credential (email, password, user_id)
                      VALUES ($1, $2, $3)'

        inserted_user = conn.exec_prepared 'user_insert',
                                           [params[:firstName],
                                            params[:lastName]]
        conn.exec_prepared 'credential_insert',
                           [params[:email], params[:password],
                            inserted_user[0]['id']]
      end
      @conn.prepare 'user_select',
                    'SELECT user_id FROM credential WHERE email=$1'
      user = @conn.exec_prepared 'user_select',
                                 [params[:email]]
      user_id = user.first
      redirect "/users/#{user_id['user_id']}"
    rescue PG::Error => e
      puts e.message
    ensure
      @conn.close if @conn
    end
  end

  get '/:id' do
    begin
      @conn.prepare 'statement', 'SELECT * FROM "user" WHERE id=$1'
      row = @conn.exec_prepared 'statement', [params[:id]]
      user = row.first
      slim :'users/show', locals: { user: user }
    rescue PG::Error => e
      puts e.message
    ensure
      @conn.close if @conn
    end
  end

  get '/:id/edit' do
    begin
      user = ''
      credential = ''
      @conn.transaction do |conn|
        conn.prepare 'user_edit', 'SELECT * FROM "user" WHERE id=$1'
        conn.prepare 'credential_edit',
                     'SELECT * FROM credential WHERE user_id = $1'
        user = conn.exec_prepared 'user_edit', [params[:id]]
        credential = conn.exec_prepared 'credential_edit', [params[:id]]

      end
      slim :'users/edit', locals: { user: user.first,
                                    credential: credential.first }
    ensure
      @conn.close if @conn
    end
  end

  post '/:id/edit' do
    begin
      @conn.transaction do |conn|
        conn.prepare 'user_update', 'UPDATE "user"
                                     SET first_name = $1, last_name = $2
                                     WHERE id = $3'
        conn.prepare 'credential_update', 'UPDATE credential
                                           SET email = $1, password = $2
                                           WHERE user_id = $3'
        conn.exec_prepared 'user_update',
                           [params[:firstName], params[:lastName], params[:id]]
        conn.exec_prepared 'credential_update',
                           [params[:email], params[:password], params[:id]]
      end
      redirect "/users/#{params[:id]}"
    rescue PG::Error => e
      puts e.message
    ensure
      @conn.close if @conn
    end
  end

  post '/:id/delete' do
    begin
      @conn.transaction do |conn|
        conn.prepare 'user_delete', 'DELETE FROM "user"
                                     WHERE id = $1'
        conn.exec_prepared 'user_delete', [params[:id]]
      end
      redirect '/users'
    rescue PG::Error => e
      puts e.message
    ensure
      @conn.close if @conn
    end
  end
end
