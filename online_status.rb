require 'data_mapper'

class Online_Status
    include DataMapper::Resource
    property :id, Serial
    property :userid, Integer
    property :status, Integer, :default => 0

    def setOnline
        self.status = 2
    end

    def setOffline
        self.status = 0
    end

    def setAway
        self.status = 1
    end
end