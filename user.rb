require 'data_mapper'

class User
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    property :user_name, String
    property :password, String
    property :helper, Boolean, :default => false
    property :administrator, Boolean, :default => false
    property :online, Integer, :default => 0

    def login(password)
    	return self.password == password
    end

    def setOnline
        self.online = 2
    end

    def setOffline
        self.offline = 0
    end

    def setAway
        self.away = 1
    end
end
