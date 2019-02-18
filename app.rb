# ---------------------------
# Requires | Gems, DBs, Funcs
# ---------------------------
require 'sinatra'
require 'data_mapper'

# ------------------------
# IGNORE | Database Config
# ------------------------
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

DataMapper.finalize

# ----------------
# Request Handlers
# ----------------
post "/register_user" do
  "NO"
end

post "/authenticate_user" do
  "NO"
end

get "/get_helpers" do
  "NO"
end

get "/get_VIP" do
  "NO"
end

get "/request_helper" do
  "NO"
end

get "/request_VIP" do
  "NO"
end
