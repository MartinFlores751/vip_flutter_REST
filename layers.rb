require 'data_mapper'

class Layer_1
    include DataMapper::Resource
    property :vip_id, Integer, :key => true
    property :helper_id, Integer, :key => true

end

class Layer_2
    include DataMapper::Resource
    property :vip_id, Integer, :key => true
    property :helper_id, Integer, :key => true

end

class Layer_3
    include DataMapper::Resource
    property :vip_id, Integer, :key => true
    property :helper_id, Integer, :key => true

end
