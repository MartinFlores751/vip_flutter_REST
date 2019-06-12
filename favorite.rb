require 'data_mapper'

class Favorites
    include DataMapper::Resource
    property :pair_id, Serial
    property :vip_id, Integer
    property :helper_id, Integer
end