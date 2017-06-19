class RdsLog

  attr_reader :log_file_name, :log_file_size

  def initialize(instance_identifier, rds_object)
    @instance_identifier = instance_identifier
    @log = rds_object
  end

  def get_json_log
    { 'instance_identifier': @instance_identifier,
      'log_file_name': @log.log_file_name,
      'last_written': @log.last_written.to_s,
      'size': @log.size
    }
  end

  def log_file_name
    @log.log_file_name
  end

  def log_file_size
    @log.size
  end

  def download_file(rds_client, log_file_name, marker)

    marker = marker || "0"
    if marker == "0"
      fmode = 'wb+'
    else
      fmode = 'ab+'
    end
    opts = {
        db_instance_identifier: @instance_identifier,
        log_file_name: @log.log_file_name,
        number_of_lines: 2000,
        marker: marker
    }

    # Start to download file and write to logfile with same name that original logfile name on RDS
    additional_data_pending = true
    begin
      File.open(log_file_name, fmode) do |file|
        while additional_data_pending do
          out = rds_client.download_db_log_file_portion(opts)
          file.write(out[:log_file_data])
          puts out[:marker]
          opts[:marker] = out[:marker]
          additional_data_pending = out[:additional_data_pending]
        end
      end
    rescue Exception => e
      puts "Error: [#{e.message}]"
      exit 1
    end

    opts[:marker]
  end




end