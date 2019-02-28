# ---------------------------
# Requires | Gems, DBs, Funcs
# ---------------------------
require 'sinatra'
require 'data_mapper'
require_relative 'user.rb'

enable :sessions

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

# -------------
# REST Handlers
# -------------
post "/api/register_user" do
  if params[:name] && params[:user] && params[:helper] && params[:password] && params[:c_password]
    if User.all(user_name: params[:user]).count == 0
      if params[:password] == params[:c_password]
        u = User.new
        u.name = params[:name]
        u.user_name = params[:user]
        u.helper = params[:helper] == '1' ? true : false
        u.password = params[:password]
        u.save
        return "Account Created!"
      end
      return "Passwords dont match!"
    end
    return "Username already exists!"
  end
  return "Field(s) Empty"
end

post "/api/authenticate_user" do
  u = User.first(user_name: params[:user])
  if u
    if u.password == params[:password]
      return "Log in Successful"
    end
    return "Incorrect Password"
  end
  return "Account does not Exist"
end

get "/api/get_helpers" do
  "NO"
end

get "/api/get_VIP" do
  "NO"
end

get "/api/request_helper" do
  "NO"
end

get "/api/request_VIP" do
  "NO"
end

# ----------------
# Web Admin Stuffs
# ----------------

get "/" do
  erb :login
end

get "/logout" do
  session[:user_name] = nil
  redirect "/"
end

post "/auth" do
  if params[:user] && params[:password]
    user = User.first(user_name: params[:user])
    if user && user.login(params[:password]) && user.administrator
      session[:user_name] = user.user_name
      redirect "/dashboard"
    else
      redirect "/"
    end
  end
end

get "/dashboard" do
  authenticate!
  erb :dashboard
end

# ----------------
# Helper Functions
# ----------------

def current_user
	if(session[:user_name])
		@u ||= User.first(user_name: session[:user_name])
		return @u
	else
		return nil
	end
end

def authenticate!
	if !current_user || !current_user.administrator
		redirect "/"
	end
end
