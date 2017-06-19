#!/usr/bin/ruby
require 'rubygems'
require 'pp'

require_relative 'lib/database'
require_relative 'lib/pgbadger'

dbconfig = {
    :host => 'localhost:27017',
    :database => 'pg'
}


pgbadger = Pgbadger.new('../out_total.json')

#db = Database.new(dbconfig)
#slowest_collection = db.get_collection('slowest')
#slowest_collection.insert_many(pgbadger.slowest)

pp pgbadger.json['normalyzed_info'].keys.size

pgbadger.json['normalyzed_info'].keys.each_with_index do |key, i|

  puts '= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = '
  puts '= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = '


  break unless i < 2
  obj = pgbadger.json['normalyzed_info'][key]
  pp obj['count']
  pp obj['duration']
  pp obj['min']
  pp obj['max']
  obj['samples'].keys.each do | sample |

    item = obj['samples'][sample]
    pp item['date'] + ' - ' + sample

  end
  #pp obj
  puts '','','',''
end


#pp obj['top_slowest'][0]

