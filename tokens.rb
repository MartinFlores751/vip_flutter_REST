require 'data_mapper'

class Tokens
    include DataMapper::Resource
    property :user_id, Integer
    property :created_at, DateTime
    property :expires, DateTime
    property :user_key, String
    property :UUID, String, :key => true
    property :last_request, DateTime
    
    def isExpired()
        now = DateTime.now
        return now > self.expires
    end

    def isOnline()
        now = DateTime.now
        offline_time = self.last_request + 300
        return now > offline_time
    end
end
