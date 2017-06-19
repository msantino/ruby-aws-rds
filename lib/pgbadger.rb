require 'json'

class Pgbadger

  KEY_SLOWEST = 'top_slowest';

  attr_reader :slowest, :json

  def initialize(json_file)
    file = File.read(json_file)
    @json = JSON.parse(file)

    # inicia o processamento do arquivo
    process_file


  end

  def process_file

    # Slowest Queries = ['top_slowest']
    proccess_slowest
  end

  def proccess_slowest
    @slowest = Array.new
    @json[KEY_SLOWEST].each do |item|
      @slowest << slowest_map(item)
    end
  end


  def slowest_map(item_array)
    return {
        'elapsed' => item_array[0].to_f,
        'date' => DateTime.strptime(item_array[1], '%Y-%m-%d %H:%M:%S'),
        'query' => item_array[2],
        'database' => item_array[3],
        'user' => item_array[4],
        'host' => item_array[5],
        'item_1' => item_array[6],
        'item_2' => item_array[7],
        'item_3' => item_array[8]
    } unless item_array.nil?
  end


end
=begin
["autovacuum_info",
 "pgb_overall_stat",
 "log_files",
 "pgb_connection_info",
 "top_slowest",
 "session_info",
 "checkpoint_info",
 "host_info",
 "user_info",
 "normalyzed_info",
 "database_info",
 "logs_type",
 "pgb_per_minute_info",
 "overall_stat",
 "pgb_error_info",
 "pgb_session_info",
 "tempfile_info",
 "per_minute_info",
 "connection_info",
 "application_info",
 "autoanalyze_info",
 "lock_info",
 "error_info",
 "nlines",
 "pgb_pool_info",
 "top_tempfile_info",
 "overall_checkpoint",
 "top_locked_info"]
=end