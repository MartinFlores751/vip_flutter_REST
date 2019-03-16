require File.expand_path '../../spec_helper.rb', __FILE__

describe 'API: ' do
  before(:all) do
    @admin = User.create(
            :name => "Bob",
            :user_name => "admax",
            :password => "admin",
            :helper => false,
            :administrator => true)

    @helper = User.create(
              :name => "Bobra",
              :user_name => "admaxin",
              :password => "adminax",
              :helper => true)

    @vip = User.create(
          :name => "Bobran",
          :user_name => "admaxinmum",
          :password => "adminaxe",
          :helper => false)

    User.create(
    :name => "Sraroto",
    :user_name => "ououtete",
    :password => "aaaaaa",
    :helper => true)

    User.create(
    :name => "Corote",
    :user_name => "cecuheco",
    :password => "naote",
    :helper => false)
  end


  describe 'When Helper' do

    before(:all) do
      now = Time.now
      @token = Tokens.create(
              :user_id => @helper.id,
              :created_at => now,
              :expires => now + 86400,                                          # Token expires in ~ 1 Day (Int is in seconds!)
              :user_key => SecureRandom.urlsafe_base64,
              :UUID => "test",
              :last_request => now)
    end
    
    it 'should allow fetching of VIP' do
      params = {token: @token.user_key,
                UUID: @token.UUID}

      get '/api/get_VIP', params

      response = last_response.body

      expect(response).to eq('["admaxinmum","cecuheco"]')
    end

  end

  describe 'When VIP' do

    before(:all) do
      now = Time.now
      @token = Tokens.create(
              :user_id => @vip.id,
              :created_at => now,
              :expires => now + 86400,                                          # Token expires in ~ 1 Day (Int is in seconds!)
              :user_key => SecureRandom.urlsafe_base64,
              :UUID => "test_VIP",
              :last_request => now)
    end

    it 'should allow fetching of Helper' do
      params = {token: @token.user_key,
                UUID: @token.UUID}

      get '/api/get_helpers', params

      response = last_response.body

      expect(response).to eq('{"success":true,"users":["admaxin","ououtete"],"error":""}')
    end

  end

  describe 'When Adimn' do

    before(:all) do
      # placeholder
    end

  end

end