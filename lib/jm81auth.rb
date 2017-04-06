require 'httpclient'
require 'jwt'

module Jm81auth
  class << self
    def config &block
      @config ||= Configuration.new
      @config.instance_eval(&block) if block_given?
      @config
    end
  end
end

require 'jm81auth/configuration'

require 'jm81auth/models/auth_method'
require 'jm81auth/models/auth_token'
require 'jm81auth/models/user'

require 'jm81auth/oauth/base'
require 'jm81auth/oauth/facebook'
require 'jm81auth/oauth/github'

require 'jm81auth/version'
