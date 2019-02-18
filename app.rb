# ///////////////////////////
# Requires | Gems, DBs, Funcs
# ///////////////////////////
require 'sinatra'
require 'data_mapper'

# ////////////////////////
# IGNORE | Database Config
# ////////////////////////
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

DataMapper.finalize

# //////////////////////////
# Request Handlers | General
# //////////////////////////
get "/" do
  
end
