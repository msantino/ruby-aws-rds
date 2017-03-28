require 'aws-sdk'
require 'highline'
require 'fileutils'

cli = HighLine.new
tmp_file = "/tmp/aws-profile.tmp"
tmp_file_contents = Array.new
File.open(tmp_file, 'a+').each { |line| tmp_file_contents << line.gsub(/[^a-zA-Z0-9\-]/,"") }
log_dir = ARGV[0] || '../logs'

#exit 1

def request_profile

end

# Solicita o profile desejado
profile_name = cli.ask("Profile:  ") { |q| q.default = tmp_file_contents[0] || 'default' }
puts "Profile escolhido: [#{profile_name}]",''
File.open(tmp_file, 'w') { |file| file << profile_name }

# Instancia o RDS do profile informado
credentials = Aws::SharedCredentials.new(profile_name: profile_name)
rds = Aws::RDS::Client.new(credentials: credentials, region: 'sa-east-1')

# Identifica as instâncias existentes na região e confirma qual será usada
instances = rds.describe_db_instances().db_instances
if instances.size == 0
  puts 'Nenhuma instância ativa'
  exit 1
end

# Solicita a instância desejada
puts 'Escolha uma das instâncias abaixo: '
instances.each do |instance|
  puts "- #{instance.db_instance_identifier} [#{instance.db_instance_class}|#{instance.engine}]"
end
puts

instance_identifier = cli.ask("Instância?  ") { |q| q.default = tmp_file_contents[1] || instances[0].db_instance_identifier }
puts "Instance-Identifier: [#{instance_identifier}]",''
File.open(tmp_file, 'a') { |file| file << "\n#{instance_identifier}" }

# Lista os arquivos de log disponiveis
begin
  logs = rds.describe_db_log_files({db_instance_identifier: instance_identifier})[0]
rescue Exception => e
  puts "Error: [#{e.message}]"
  exit 1
end

puts 'Looking for available Logfile: '
logs.each_with_index do |log, i|
  puts "[#{i}] - #{log.log_file_name} [#{(log[:size].to_f/1024/1024).to_s}]"
end

log_index = cli.ask("Log desejado:  ") { |q| q.default = (logs.size-1).to_s }
File.open(tmp_file, 'a') { |file| file << "\n#{log_index}" }
puts
puts

puts 'Chosen logfile:'
last_log = logs[log_index.to_i]
puts last_log.log_file_name,''

puts 'Downloading file contents...'
opts = {
          db_instance_identifier: instance_identifier,
          log_file_name: last_log.log_file_name,
          number_of_lines: 1000,
          marker: "0"
      }

# Defines logfile path and creates if still doesnt exists
log_dir = log_dir + '/' + instance_identifier
begin
  FileUtils.mkdir_p log_dir
rescue Exception => e
  puts "Error: [#{e.message}]"
  exit 1
end

# Logfile name with full path
log_name = log_dir + '/' + opts[:log_file_name].split("/")[1] + '.log'

# Start to download file and write to logfile with same name that original logfile name on RDS
additional_data_pending = true
begin
  File.open(log_name, "wb+") do |file|
    while additional_data_pending do
      out = rds.download_db_log_file_portion(opts)
      file.write(out[:log_file_data])
      puts out[:marker]
      opts[:marker] = out[:marker]
      additional_data_pending = out[:additional_data_pending]
    end
  end
  puts 'done',''
  if File.exists?(log_name)
    puts 'RDS log downloaded to file ' + log_name + ' with ' + (File.size(log_name).to_f/1024/1024).to_s + 'Mb'
  end
rescue Exception => e
  puts "Error: [#{e.message}]"
  exit 1
end

puts
puts