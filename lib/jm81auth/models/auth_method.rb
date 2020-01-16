module Jm81auth
  module Models
    module AuthMethod
      def self.included(base)
        base.extend ClassMethods

        base.class_eval do
          if respond_to? :belongs_to
            belongs_to :user
            has_many :auth_tokens
          else
            many_to_one :user
            one_to_many :auth_tokens
          end
        end
      end

      # Create AuthToken, setting user and last_used_at, and optionally
      # access_token from the Oauth provider.
      #
      # @return [AuthToken]
      def create_token access_token: nil
        auth_token = ::AuthToken.new
        auth_token.auth_method = self
        auth_token.user = user
        auth_token.last_used_at = Time.now.utc

        if auth_token.respond_to? :access_token=
          auth_token.access_token = access_token
        end

        auth_token.save
        auth_token
      end

      module ClassMethods
        # Get an AuthMethod using provider data conditions (#provider_name and
        # #provider_id).
        #
        # @param provider_data [Hash]
        # @return [AuthMethod]
        def by_provider_data provider_data
          where(provider_data).first
        end
      end
    end
  end
end
