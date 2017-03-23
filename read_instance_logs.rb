require 'aws-sdk'
require 'highline'

cli = HighLine.new
tmp_file = "/tmp/aws-profile.tmp"
tmp_file_contents = Array.new
File.open(tmp_file, 'a+').each { |line| tmp_file_contents << line.gsub(/[^a-zA-Z0-9\-]/,"") }

#exit 1

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

puts 'Logs disponíveis: '
logs.each_with_index do |log, i|
  puts "[#{i}] - #{log.log_file_name}"
end

log_index = cli.ask("Log desejado:  ") { |q| q.default = (logs.size-1).to_s }
File.open(tmp_file, 'a') { |file| file << "\n#{log_index}" }

puts 'Looking for available Logfile: '
last_log = logs[logs.size-(log_index.to_i+1)]
puts last_log.log_file_name,''

puts 'Log file contents: '
begin
  log_file = rds.download_db_log_file_portion({
                db_instance_identifier: instance_identifier,
                log_file_name: last_log.log_file_name
            })
rescue Exception => e
  puts "Error: [#{e.message}]"
  exit 1
end

puts log_file.log_file_data,''



