# ---------------------------
# Requires | Gems, DBs, Funcs
# ---------------------------
require 'sinatra'
require 'data_mapper'
require 'securerandom'
require_relative 'user.rb'
require_relative 'tokens.rb'
require_relative 'online_status.rb'
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
  response = {:success => false, :error => ''}  # Response JSON

  # Check that all params have been sent
  if params[:name] && params[:user] && params[:helper] && params[:password] && params[:c_password] && params[:UUID]

    # Check that the user does not exist
    if User.all(user_name: params[:user]).count == 0

      # Check that the password and confirmation password match
      if params[:password] == params[:c_password]

        # Create a new user
        u = User.create(
            :name => params[:name],
            :user_name => params[:user],
            :helper => params[:helper] == '1' ? true : false,
            :password => params[:password])

        response[:success] = true
        return response.to_json # Return JSON response showing successful creation
      end

      response[:error] = "Passwords dont match!"
      return response.to_json # Return JSON response showing passwords failed to match
    end

    response[:error] = "Username already exists!"
    return response.to_json # Return JSON response showing username is already taken
  end

  response[:error] = "Field(s) Empty"
  return response.to_json # Return JSON response showing not all data has been sent
end

post "/api/authenticate_user" do
  response = {:success => false, :token => '', :error => '', :isHelper => ''} # JSON response

  # Check that all parameters have been passed
  if params[:user] && params[:UUID] && params[:password]
    u = User.first(:user_name => params[:user]) # Get user for comparison

    # If username does not exist...
    unless u
      response[:error] = "Account does not Exist"
      return response.to_json # Return account does not exist error
    end

    # Check to see if the password is valid
    if u.password == params[:password]

       token = Tokens.first(:UUID => params[:UUID], :user_id =>u.id) # Get the token using given UUID and user id

      # If a token exists...
       if token != nil
        # And is not expired...
         if !token.isExpired
          response[:success] = true
          response[:token] = token.user_key
          response[:isHelper] = u.helper
          return response.to_json # Return success and the token to the user, otherwise...
         end
         token.destroy # Destroy token if expired
       end

      # Create a new token for the User's Device...
       now = DateTime.now # Using the current time
       t = Tokens.create(
         :user_id => u.id,
         :created_at => now,
         :expires => now + 1,                        # Token expires in ~ 1 Day
         :user_key => SecureRandom.urlsafe_base64,
         :UUID => params[:UUID])
      
      # Create the success JSON response
      response[:success] = true
      response[:token] = t.user_key
      response[:isHelper] = u.helper
      return response.to_json # Return the JSON response with the new key
    end

    response[:error] = "Incorrect Password"
    return response.to_json # Return the JSON response signifying Incorrect Password
  end
end

post "/api/get_helpers" do
  response = {:success => false, :users => '[]', :error => ''} # JSON Response

  # Check that UUID and Token were passed
  if params[:token] && params[:UUID]

    # Check that the Token exists and that that recived token matches the retrieved DB token
    if rest_authenticate(params[:token], params[:UUID])
      
      # Create response JSON
      response[:users] = rest_get_users_JSON(false)
      response[:success] = true

      return response.to_json # Return successful JSON response with list of helpers
     end

    response[:error] = "Invalid token"
    return response.to_json # Return JSON response with Invalid token error
  end

  response[:error] = "Missing parameter(s)"
  return response.to_json # Return JSON response with Missing parameters error
end

post "/api/get_VIP" do
  response = {:success => false, :users => '[]', :error => ''} # JSON response

  # Check that token and UUID were passed
  if params[:token] && params[:UUID]
    
    # Check that the token is valid
    if rest_authenticate!(params[:token], params[:UUID])
      
      # Create Response JSON
      response[:users] = rest_get_users_JSON(true)
      response[:success] = true

      return response.to_json # Return successful JSON Response with list of VIPs
     end

    response[:error] = "Invalid token"
    return response.to_json # Return JSON Response with invalid token error
  end

  response[:error] = "Missing parameter(s)"
  return response.to_json # Return JSON Response with Missing parameter(s) error
end

# -----------
# Unused APIS
# -----------
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

def rest_authenticate!(token, user_UUID)
  t = Tokens.first(:UUID => user_UUID, :user_key => token) # Get the corresponding token

  # Check that the token exists and matches the corresponding token
  if t && t.user_key == params[:token]
    return true # Token exists, return true
  end

  false # Token doesn't exist, return false
end

def rest_get_users_JSON(getVIP)
  u_js = [] # JS array to return

  if getVIP
    users = User.all(:helper => false, :administrator => false) # Gather all VIPs, ignore admin
  else
    users = User.all(:helper => true, :administrator => false) # Gather all Helpers, ignore admin
  end
  
  # Create array containing all VIPs or all Helpers
  users.each do |u|
    u_js.push(u.user_name)
  end

  # Create JSON array and return it
  u_js.to_json
end
