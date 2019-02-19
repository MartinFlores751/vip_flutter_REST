require 'data_mapper'

class User
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    property :user_name, String
    property :password, String
    property :helper, Boolean, :default => false
    property :administrator, Boolean, :default => false

    def login(password)
    	return self.password == password
    end
end
