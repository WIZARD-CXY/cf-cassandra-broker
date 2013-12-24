require 'cql'

class ServiceInstance
  attr_accessor :id , :client

  Keyspace_PREFIX = 'cf_'.freeze

  def initialize(id)
    @id=id
    host = Rails.configuration.database_configuration[Rails.env].fetch('host')
    username = Rails.configuration.database_configuration[Rails.env].fetch('username')
    password = Rails.configuration.database_configuration[Rails.env].fetch('password')

    @client = Cql::Client.connect(hosts: [host], credentials:{"username"=>username,"password"=>password})
  end


  def self.find_by_id(id)
    new(id: id)
  #  instance if instance.client.execute("SHOW DATABASES LIKE '#{instance.keyspaceName}'").any?
  end


  def self.find(id)
    find_by_id(id) || raise("Couldn't find ServiceInstance with id=#{id}")
  end

  #Not implement yet
  #def self.exists?(id)
  #  find_by_id(id).present?
  #end

  #Not implement yet
  #def self.get_number_of_existing_instances
  #  connection.select("select count(*) from information_schema.SCHEMATA where schema_name LIKE 'cf_%'").rows.first.first
  #end

  def getKeyspaceName
      if id =~ /[^0-9,a-z,A-Z$-]+/
        raise 'Only ids matching [0-9,a-z,A-Z$-]+ are allowed'
      end

      keyspace = id[:id].gsub('-', '_')

      "#{Keyspace_PREFIX}#{keyspace}"
  end

  # now is hard coded replication strategy
  def save
    @client.execute("CREATE KEYSPACE #{getKeyspaceName} WITH replication = {'class': 'SimpleStrategy','replication_factor': 3}")
  end

  def destroy
    @client.execute("DROP KEYSPACE #{getKeyspaceName}")
  end

  def to_json(*)
    {}.to_json
  end
end
