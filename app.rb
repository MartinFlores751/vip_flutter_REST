# ---------------------------
# Requires | Gems, DBs, Funcs
# ---------------------------
require 'sinatra'
require 'data_mapper'
require 'securerandom'
require 'json'
require 'base64'
require_relative 'user.rb'
require_relative 'tokens.rb'
require_relative 'online_status.rb'
require_relative 'favorite.rb'

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
Favorites.auto_upgrade!
OnlineStatus.auto_upgrade!

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
before "/api/*" do
  unless (params[:splat][0]) == 'register_user'

    response = {:success => false, :error => ''}
    auth = env['HTTP_AUTHORIZATION'] # Retrive auth typ and pass
    methodAndPass = auth.to_s.split(' ')

    if methodAndPass[0] == 'Basic'
      print "Basic Auth\n"

      userAndPass = Base64.decode64(methodAndPass[1])
      userPass = userAndPass.split(' ')
      usernameAndPassword = userPass[0].split(':')
      user = User.first(:user_name => usernameAndPassword[0])

      if user && user.login(usernameAndPassword[1])
        print "Successfully authed!\n"
        session[:user_name] = user.user_name
        pass
      end
    end

    
    unless rest_authenticate!(session[:token], params[:UUID])
      print "Auth fail!\n"
      response[:error] = 'Invalid auth type!'
      halt 401, {'Content-Type' => 'application/json'}, response.to_json # Catch all for invalid login
    end

    print "Successfully authed!\n"
    pass
  end
end

post "/api/register_user", :provides => :json do
  content_type :json
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

        #create that same user for OnlineStatus
        OnlineStatus.create(
            :status => 0,
            :user_id => u.id
        )

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

post "/api/authenticate_user", :provides => :json do
  content_type :json
  response = {:success => false, :error => '', :isHelper => ''} # JSON response

  # Check that all parameters have been passed
  if params[:UUID]
    u = User.first(:user_name => session[:user_name]) # Get user for comparison
    token = Tokens.first(:UUID => params[:UUID], :user_id =>u.id) # Get the token using given UUID and user id
    session[:user_name] = u.user_name
    # If a token exists...
      if token != nil
      # And is not expired...
        unless  token.isExpired
          response[:success] = true
          session[:token] = token.user_key
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
    session[:token] = t.user_key
    response[:isHelper] = u.helper
    return response.to_json # Return the JSON response with the new key
  end

  response[:error] = "Incorrect Password"
  return response.to_json # Return the JSON response signifying Incorrect Password
end

post "/api/get_favorites", :provides => 'json' do
  content_type :json
  response = {:success => false, :favorites => '[]', :error => ''}

  # Check that all needed params are passed
  if params[:UUID] && params[:isHelper]

    # Check that token and UUID pair is valid
    if rest_authenticate!(session[:token], params[:UUID])
      token = Tokens.first(:user_key => session[:token], :UUID => params[:UUID])
      response[:favorites] = rest_get_friends_JSON(token.user_id, params[:isHelper])
      response[:success] = true
      return response
    end

    response[:error] = 'Authentification failed!'
    return response
  end

  response[:error] = 'Not all parameters passed'
  return response
end

post "/api/get_helpers", :provides => 'json' do
  content_type :json
  response = {:success => false, :users => '[]', :error => ''} # JSON Response

  # Check that UUID and Token were passed
  if params[:UUID]
    # Create response JSON
    response[:users] = rest_get_users_JSON(false)
    response[:success] = true

    return response.to_json # Return successful JSON response with list of helpers
  end
  
  response[:error] = "Missing parameter(s)"
  return response.to_json # Return JSON response with Missing parameters error
end

post "/api/get_VIP", :provides => 'json' do
  content_type :json
  response = {:success => false, :users => '[]', :error => ''} # JSON response

  # Check that token and UUID were passed
  if params[:UUID]
    
    # Check that the token is valid
    if rest_authenticate!(session[:token], params[:UUID])
      
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

post "/api/set_status", :provides => 'json' do
  content_type :json
  response = {:success => false, :status => 0, :error => ''} # JSON Response

  #check that the token, the UUID, and the userid were passed
  if params[:UUID] && params[:status]

    token = Tokens.first(:user_key => session[:token], :UUID => params[:UUID])

    # If the token exists...
    if token != nil
      # And is not expired...
      if token.isExpired
        response[:success] = false
        response[:status] = -1
        response[:error] = "Please log in again!"
        return response.to_json # Return success and the token to the user, otherwise...
      end

      #check that the token is valid
      if rest_authenticate!(session[:token], params[:UUID])

        #set the status of the user
        u = OnlineStatus.first(:user_id => token.user_id)
        if u == nil
          print 'THERE IS NO ONLINE STATUS!!!!'
        end
        status = params[:status]
        if status == '2'
          u.setOnline
        elsif status == '1'
          u.setAway
        else
          u.setOffline
        end
        u.save
        response[:success] = true
        response[:status] = params[:status]
        return response.to_json
      end
    end
  end

  #if the params are invalid return error response
  response[:success] = false
  response[:status] = -1
  response[:error] = "Invalid parameters"
  return response.to_json
end

post "/api/add_favorites", :provides => 'json' do
  content_type :json
  response = {:success => false, :error => ''};
  if params[:UUID] && params[:username]
    print "TEMP: I now declare you friends...\n"
  else
    response[:error] = 'Missing arguments!'
    return response.to_json
  end
end

# -----------
# Unused APIS
# -----------
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

#this displays the selected user's profile when you click on their name
get "/user_profile" do
  authenticate!
  if params[:user_name]
    @user = User.first(user_name: params[:user_name])
    erb :user_profile
  else
    redirect "/dashboard"
  end
end

get "/dashboard" do
  authenticate!
  #get all VIP & Helper users & online users to display onto the dashboard
  @vipUsers = User.all(:helper => false, :administrator => false)
  @helperUsers = User.all(:helper => true, :administrator => false)
  @allUsers = User.all()
  @finalOnlineUsers = []
  #for each user, get their online status
  #if their online status is 2, then push
  #user into the finalOnlineUsers array
  @allUsers.each do |x|
    user = OnlineStatus.first(:user_id => x.id)
    if user != nil
      if user.status == 2
        @finalOnlineUsers.push(x)
      end
    end
  end
  erb :dashboard
end

# ----------------
# Helper Functions
# ----------------
helpers do 
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

  def rest_authenticate!(token, userUUID)
    t = Tokens.first(:UUID => userUUID, :user_key => token) # Get the corresponding token

    # Check that the token exists and matches the corresponding token
    if t
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

  def rest_get_friends_JSON(userID, isHelper)
    f_js = []
    f_id = []

    if isHelper
      friends = Friends.all(:helper_id => userID)

      friends.each do |f|
        f_id.push(f.vip_id)
      end
    else
      friends = Friends.all(:vip_id => userID)

      friends.each do |f|
        f_id.push(f.helper_id)
      end
    end

    f_id.each do |id|
      u = User.get(id)
      f_js.push(u.user_name)
    end

    return f_js.to_json
  end
end
