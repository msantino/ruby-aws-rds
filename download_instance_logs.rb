#!/usr/bin/ruby
require 'rubygems'
require 'pp'
require 'aws-sdk'
require 'highline'
require 'fileutils'

require_relative 'lib/database'
require_relative 'lib/rds_log'


dbconfig = {
    :host => 'localhost:27017',
    :database => 'pg'
}

db = Database.new(dbconfig)
rds_logs = db.get_collection('rds_logs')

cli = HighLine.new

tmp_file = "/tmp/aws-profile.tmp"
tmp_file_contents = Array.new
File.open(tmp_file, 'a+').each { |line| tmp_file_contents << line.gsub(/[^a-zA-Z0-9\-]/,"") }
log_dir = ENV['RDS_LOG_PATH'] || '../logs'

# Solicita o profile desejado
# Se a variavel for definida por ENV, usa ela. Caso contrario pede
if ENV['RDS_PROFILE_NAME']
  profile_name = ENV['RDS_PROFILE_NAME']
else
  profile_name = cli.ask("Profile:  ") { |q| q.default = tmp_file_contents[0] || 'default' }
  puts "Profile escolhido: [#{profile_name}]",''
  File.open(tmp_file, 'w') { |file| file << profile_name }
end

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

# Se a variavel for definida por ENV, usa ela. Caso contrario pede
if ENV['RDS_INSTANCE_IDENTIFIER']
  instance_identifier = ENV['RDS_INSTANCE_IDENTIFIER']
else
  instance_identifier = cli.ask("Instância?  ") { |q| q.default = tmp_file_contents[1] || instances[0].db_instance_identifier }
  puts "Instance-Identifier: [#{instance_identifier}]",''
  File.open(tmp_file, 'a') { |file| file << "\n#{instance_identifier}" }
end

# Garante a existencia do diretorio desejado
log_dir = log_dir + '/' + instance_identifier
begin
  FileUtils.mkdir_p log_dir
rescue Exception => e
  puts "Error: [#{e.message}]"
  exit 1
end

# Lista os arquivos de log disponiveis
begin
  logs = rds.describe_db_log_files({db_instance_identifier: instance_identifier})[0]
rescue Exception => e
  puts "Error: [#{e.message}]"
  exit 1
end

puts 'Looking for available Logfile: '

logs.each_with_index do |log, i|

  puts '',''
  pp '= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = ='
  pp "Iniciando processamento do arquivo log.log_file_name"
  pp '= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = ='

  next unless i != 68
  # puts "[#{i}] - #{log.log_file_name} [#{(log[:size].to_f/1024/1024).to_s}]"

  rds_log = RdsLog.new( instance_identifier, log)

  log_db = rds_logs.find({instance_identifier: instance_identifier, log_file_name: log.log_file_name}).first

  if log_db.nil?
    # Insere os dados do log no banco se nao existir
    insert = rds_logs.insert_one( rds_log.get_json_log ) unless not log_db.nil?

    log_db = rds_logs.find({instance_identifier: instance_identifier, log_file_name: log.log_file_name}).first

  end


  pp log_db
  # Checa se o arquivo já existe no caminho de logs
  log_file_name = log_dir + '/' + log.log_file_name.split("/")[1] + '.log'
  pp "RDS Log size: #{log.size}"
  if File.exists?(log_file_name) && (File.size(log_file_name)+102400) >= log.size
    pp "Local file size: #{File.size(log_file_name).to_s}"
    pp "File #{log.log_file_name} already exists and complete downloaded."
    next
  end

  marker = rds_log.download_file(rds, log_file_name, log_db['marker'])
  #pp "Downloading file #{log.log_file_name} [#{File.size(log_file_name).to_s}]"

  # Atualiza o tamanho do arquivo e o marker no banco
  update = rds_logs.update_one( {instance_identifier: instance_identifier, log_file_name: log.log_file_name},
                                  { '$set' => { 'marker' => marker,
                                                'updated_at' => DateTime.now(),
                                                'file_size' => File.size(log_file_name) } } )

  pp update

  puts '',''
end

exit 1


puts
puts