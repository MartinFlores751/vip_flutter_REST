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
  response = {:success => false, :error => ''}
  if params[:name] && params[:user] && params[:helper] && params[:password] && params[:c_password] && params[:UUID]
    if User.all(user_name: params[:user]).count == 0
      if params[:password] == params[:c_password]
        u = User.create(
            :name => params[:name],
            :user_name => params[:user],
            :helper => params[:helper] == '1' ? true : false,
            :password => params[:password])
        response[:success] = true
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
  if params[:user] && params[:UUID] && params[:password]
    u = User.first(user_name: params[:user])
    if u
      if u.password == params[:password]
        u.setOnline
        u.save!
        token = Tokens.get(:UUID => params[:UUID], :user_id => params[:u.id])

        if token != nil
          if !token.isExpired
            response[:success] = true
            response[:token] = token.user_key
            response[:isHelper] = u.helper
            return response.to_json
          else
            token.destroy
          end
        end

        now = DateTime.now
        t = Tokens.create(
          :user_id => u.id,
          :created_at => now,
          :expires => now + 1,                                          # Token expires in ~ 1 Day (Int is in seconds!)
          :user_key => SecureRandom.urlsafe_base64,
          :UUID => params[:UUID])
        
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

post "/api/get_helpers" do
  response = {:success => false, :users => '[]', :error => ''}
  if params[:token] && params[:UUID]
    t = Tokens.get(params[:UUID])
    if t && t.user_key == params[:token]
      u_js = []
      users = User.all(:helper => true, :administrator => false)
      users.each do |u|
        u_js.push(u.user_name)
      end
      response[:users] = u_js.to_json
      response[:success] = true
      return response.to_json
    end
    response[:error] = "Invalid token"
    return response.to_json
  end
  response[:error] = "Missing parameter(s)"
  return response.to_json
end

post "/api/get_VIP" do
  response = {:success => false, :users => '[]', :error => ''}
  if params[:token] && params[:UUID]
    t = Tokens.get(params[:UUID])
    if t && t.user_key == params[:token]
      u_js = []
      users = User.all(:helper => false, :administrator => false)
      users.each do |u|
        u_js.push(u.user_name)
      end
      response[:users] = u_js.to_json
      response[:success] = true
      return response.to_json
    end
    response[:error] = "Invalid token"
    return response.to_json
  end
  response[:error] = "Missing parameter(s)"
  return response.to_json
end

post "/api/logout" do
  "No"
end

post "/api/set_status" do
  "No"
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
