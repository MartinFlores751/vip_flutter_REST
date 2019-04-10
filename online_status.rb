require 'data_mapper'

class Online_Status
    include DataMapper::Resource
    property :id, Serial
    property :userid, Integer
    property :status, Integer, :default => 0

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