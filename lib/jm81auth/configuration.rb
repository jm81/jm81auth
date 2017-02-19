class Configuration
  attr_accessor :client_secrets, :expires_seconds, :jwt_algorithm, :jwt_secret

  def initialize
    @client_secrets = {}
    @expires_seconds = 30 * 86400
    @jwt_algorithm = 'HS512'
  end
end
