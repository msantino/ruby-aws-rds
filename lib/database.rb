require 'mongo'
class Database

  def initialize(config)
    mongo = Mongo::Client.new([ config[:host] ], :database => config[:database])
    @db = mongo.database
  end

  def get_collection(collection)
    @db.collection(collection)
  end



end