require File.expand_path '../../spec_helper.rb', __FILE__


describe User do
  it { should have_property :id }
  it { should have_property :name }
  it { should have_property :user_name }
  it { should have_property :password }
  it { should have_property :helper }
  it { should have_property :administrator }
end


describe Tokens do
  it { should have_property :user_id }
  it { should have_property :created_at }
  it { should have_property :expires }
  it { should have_property :user_key }
  it { should have_property :UUID }
  it { should have_property :last_request }
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
