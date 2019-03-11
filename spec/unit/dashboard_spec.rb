require File.expand_path '../../spec_helper.rb', __FILE__


describe 'VIP App' do

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

  it 'should allow accessing the login' do
    get '/'
    expect(last_response).to be_ok
  end


  it 'should not be signed in by default' do
    visit '/'
    expect { page.get_rack_session_key('user_id') }.to raise_error(KeyError)
  end

  describe 'When not logged in' do

    it 'should not allow access to /dashboard' do
      visit '/dashboard'
      expect(page).to have_current_path('/')
    end
    
  end
  
end
