class ServiceBinding < BaseModel
  attr_accessor :id, :service_instance

  # Returns a given binding, if the MySQL user exists.
  #
  # NOTE: This method cannot currently check for the true existence of
  # the binding. A binding is the association of a MySQL user with a
  # database. We use the binding id to identify a user and the instance
  # id to identify a database. As such, we really need both ids to be
  # sure the binding exists. This problem is resolvable by persisting
  # both ids and their relationship in a separate management database.

  def self.find_by_id(id)
    binding = new(id: id)

    begin
      connection.execute("SHOW GRANTS FOR '#{binding.username}'")
      binding
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ /no such grant/
    end
  end

  # Returns a given binding, if it exists.
  #
  # NOTE: This method is only necessary because of the current
  # shortcomings of +find_by_id+. And because it requires both
  # the binding id and the instance id, it cannot currently be
  # used by the binding controller.

  def self.find_by_id_and_service_instance_id(id, instance_id)
    instance = ServiceInstance.new(id: instance_id)
    binding = new(id: id)

    begin
      grants = connection.select_values("SHOW GRANTS FOR '#{binding.username}'")

      # Can we do this more elegantly, i.e., without checking for a
      # particular raw GRANT statement?
      if grants.include?("GRANT ALL PRIVILEGES ON `#{instance.database}`.* TO '#{binding.username}'@'%'")
        binding
      end
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ /no such grant/
    end
  end

  # Checks to see if the given binding exists.
  #
  # NOTE: This method uses +find_by_id_and_service_instance_id+ to
  # verify true existence, and thus cannot currently be used by the
  # binding controller.

  def self.exists?(conditions)
    id = conditions.fetch(:id)
    instance_id = conditions.fetch(:service_instance_id)

    find_by_id_and_service_instance_id(id, instance_id).present?
  end

  def host
    connection_config.fetch('host')
  end

  def port
    connection_config.fetch('port')
  end

  def database
    service_instance.database
  end

  def username
    Digest::MD5.base64digest(id).gsub(/[^a-zA-Z0-9]+/, '')[0...16]
  end

  def password
    @password ||= SecureRandom.base64(20).gsub(/[^a-zA-Z0-9]+/, '')[0...16]
  end

  def save
    connection.execute("CREATE USER '#{username}' IDENTIFIED BY '#{password}'")
    connection.execute("GRANT ALL PRIVILEGES ON `#{database}`.* TO '#{username}'@'%'")

    # Some MySQL installations, e.g., Travis, seem to need privileges
    # to be flushed even when using the appropriate account management
    # statements, despite what the MySQL documentation says:
    # http://dev.mysql.com/doc/refman/5.6/en/privilege-changes.html
    connection.execute('FLUSH PRIVILEGES')
  end

  def destroy
    begin
      connection.execute("DROP USER '#{username}'")
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ /DROP USER failed/
    else
      # Some MySQL installations, e.g., Travis, seem to need privileges
      # to be flushed even when using the appropriate account management
      # statements, despite what the MySQL documentation says:
      # http://dev.mysql.com/doc/refman/5.6/en/privilege-changes.html
      connection.execute('FLUSH PRIVILEGES')
    end
  end

  def to_json(*)
    {
      'credentials' => {
        'hostname' => host,
        'port' => port,
        'name' => database,
        'username' => username,
        'password' => password,
        'uri' => uri,
        'jdbcUrl' => jdbc_url
      }
    }.to_json
  end

  private

  def connection_config
    Rails.configuration.database_configuration[Rails.env]
  end

  def uri
    "mysql://#{username}:#{password}@#{host}:#{port}/#{database}?reconnect=true"
  end

  def jdbc_url
    "jdbc:mysql://#{username}:#{password}@#{host}:#{port}/#{database}"
  end
end
