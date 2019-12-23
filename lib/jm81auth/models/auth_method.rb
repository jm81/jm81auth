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

      # Create AuthToken, setting user and last_used_at
      #
      # @return [AuthToken]
      def create_token
        if respond_to? :belongs_to
          auth_tokens.create! user: user, last_used_at: Time.now.utc
        else
          add_auth_token user: user, last_used_at: Time.now.utc
        end
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
