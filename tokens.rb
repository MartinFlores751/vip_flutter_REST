require 'data_mapper'

class Tokens
    include DataMapper::Resource
    property :user_id, Integer
    property :created_at, DateTime
    property :expires, DateTime
    property :user_key, String
    property :UUID, String, :key => true
    
    def isExpired()
        now = DateTime.now
        return now > self.expires
    end
end
