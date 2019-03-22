require File.expand_path '../../spec_helper.rb', __FILE__


describe User do
  it { should have_property :id }
  it { should have_property :name }
  it { should have_property :user_name }
  it { should have_property :password }
  it { should have_property :helper }
  it { should have_property :administrator }
  it { should have_property :online }
end


describe Tokens do
  it { should have_property :user_id }
  it { should have_property :created_at }
  it { should have_property :expires }
  it { should have_property :user_key }
  it { should have_property :UUID }

  it 'should accept unexpired token' do
    now = DateTime.now
    token = Tokens.create(
      :user_id => 2000,
      :created_at => now,
      :expires => now + 1,                                          
      :user_key => SecureRandom.urlsafe_base64,
      :UUID => "teaoeust")
    
    expect(token.isExpired).to eq(false)
  end

  it 'should reject expired token' do
    now = DateTime.now
    token = Tokens.create(
      :user_id => 2001,
      :created_at => now,
      :expires => now - 1,                                          
      :user_key => SecureRandom.urlsafe_base64,
      :UUID => "teaoeustaue")
    
    expect(token.isExpired).to eq(true)
  end
end

describe Layer_1 do
  it { should have_property :vip_id }
  it { should have_property :helper_id }
end

describe Layer_2 do
  it { should have_property :vip_id }
  it { should have_property :helper_id }
end

describe Layer_3 do
  it { should have_property :vip_id }
  it { should have_property :helper_id }
end
