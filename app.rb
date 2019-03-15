# ---------------------------
# Requires | Gems, DBs, Funcs
# ---------------------------
require 'sinatra'
require 'data_mapper'
require 'securerandom'
require_relative 'user.rb'
require_relative 'tokens.rb'
require_relative 'layers.rb'

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
Tokens.auto_upgrade!
Layer_1.auto_upgrade!
Layer_2.auto_upgrade!
Layer_3.auto_upgrade!

# ----------------------
# Create admin for later
# ----------------------
if User.all(administrator: true).count == 0
  User.create(
  :name => "cool-group",
  :user_name => "admax",
  :password => "admin",
  :administrator => true)
end

# -------------
# REST Handlers
# -------------
post "/api/register_user" do
  response = {:success => false, :error => '', :token => ''}
  if params[:name] && params[:user] && params[:helper] && params[:password] && params[:c_password] && params[:UUID]
    if User.all(user_name: params[:user]).count == 0
      if params[:password] == params[:c_password]
        u = User.create(
            :name => params[:name],
            :user_name => params[:user],
            :helper => params[:helper] == '1' ? true : false,
            :password => params[:password])

        now = Time.now
        t = Tokens.create(
            :user_id => u.id,
            :created_at => now,
            :expires => now + 86400,                                          # Token expires in ~ 1 Day (Int is in seconds!)
            :user_key => SecureRandom.urlsafe_base64,
            :UUID => params[:UUID],
            :last_request => now) 

        response[:success] = true
        response[:token] = t.user_key
        return response.to_json
      end
      response[:error] = "Passwords dont match!"
      return response.to_json
    end
    response[:error] = "Username already exists!"
    return response.to_json
  end
  response[:error] = "Field(s) Empty"
  return response.to_json
end

post "/api/authenticate_user" do
  response = {:success => false, :token => '', :error => '', :isHelper => ''}
  if params[:user] && params[:UUID]
    u = User.first(user_name: params[:user])
    if u
      if u.password == params[:password]
        token = Tokens.get(params[:UUID])

        if token != nil
          if !token.isExpired
            return token.user_key
          else
            token.destroy
          end
        end

        now = Time.now
        t = Tokens.create(
          :user_id => u.id,
          :created_at => now,
          :expires => now + 86400,                                          # Token expires in ~ 1 Day (Int is in seconds!)
          :user_key => SecureRandom.urlsafe_base64,
          :UUID => params[:UUID],
          :last_request => now
        )
        response[:success] = true
        response[:token] = t.user_key
        response[:isHelper] = u.helper
        return response.to_json
      end
      response[:error] = "Incorrect Password"
      return response.to_json
    end
    response[:error] = "Account does not Exist"
    return response.to_json
  end
end

get "/api/get_helpers" do
  response = {:success => false, :users => [], :error => ''}
  if params[:token] && params[:UUID]
    t = Tokens.get(params[:UUID])
    if t && t.user_key == params[:token]
      u_js = []
      users = User.all(:helper => true)
      users.each do |u|
        u_js.push(u.user_name)
      end
      response[:users] = u_js
      response[:success] = true
      return response.to_json
    end
    response[:error] = "Invalid token"
    return response
  end
  response[:error] = "Missing parameter(s)"
  return response.to_json
end

get "/api/get_VIP" do
  if params[:token] && params[:UUID]
    t = Tokens.get(params[:UUID])
    if t && t.user_key == params[:token]
      u_js = []
      users = User.all(:helper => false)
      users.each do |u|
        u_js.push(u.user_name)
      end
      return u_js.to_json
    end
  end
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
