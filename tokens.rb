require 'data_mapper'

class Tokens
    include DataMapper::Resource
    property :user_id, Integer
    property :created_at, DateTime
    property :expires, DateTime
    property :user_key, String
    property :UUID, String, :key => true
    
    def isExpired()
        now = Time.now
        print now
        print self.expires.to_time
        return now > self.expires.to_time
    end
end
