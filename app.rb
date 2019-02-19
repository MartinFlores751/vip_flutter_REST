# ---------------------------
# Requires | Gems, DBs, Funcs
# ---------------------------
require 'sinatra'
require 'data_mapper'
require_relative 'user.rb'

# ------------------------
# IGNORE | Database Config
# ------------------------
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

DataMapper.finalize
User.auto_upgrade!

# ----------------------
# Create admin for later
# ----------------------
if User.all(administrator: true).count == 0
  u = User.new
  u.name = "cool-group"
  u.user_name = "admax"
  u.password = "admin"
  u.administrator = true
  u.save
end

# ----------------
# Request Handlers
# ----------------
post "/register_user" do
  if params[:name] && params[:user] && params[:helper] && params[:password] && params[:c_password]
    if User.all(user_name: params[:user]).count == 0
      if params[:password] == params[:c_password]
        u = User.new
        u.name = params[:name]
        u.user_name = params[:user]
        u.helper = params[:helper] == 't' ? true : false
        u.password = params[:password]
        u.save
        return "Account Created\n"
      end
    end
  end
  "OOF\n"
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
