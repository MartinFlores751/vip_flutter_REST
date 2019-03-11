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
        now = Time.now
        return now > self.expires.to_time
    end

    def isOnline()
        now = Time.now
        offline_time = self.last_request + 300
        return now > offline_time
    end
end
