module Jm81auth
  module Models
    module AuthToken
      def self.included(base)
        base.extend ClassMethods

        base.class_eval do
          plugin :timestamps

          many_to_one :auth_method
          many_to_one :user
        end
      end

      class DecodeError < StandardError
      end

      # Set #closed_at. Called, for example, when logging out.
      def close!
        self.update(closed_at: Time.now) unless self.closed_at
      end

      # @return [String]
      #   { auth_token_id: self.id } encoded via JWT for passing to client.
      def encoded
        self.class.encode auth_token_id: self.id
      end

      # @return [Boolean] Is this token expired?
      def expired?
        !open?
      end

      # @return [Boolean] True if token is not expired or closed.
      def open?
        !(last_used_at.nil?) && !closed_at && Time.now <= expires_at
      end

      # @return [DateTime] Time when this token expires.
      def expires_at
        last_used_at + self.class.config.expires_seconds
      end

      module ClassMethods

        # Decode a JWT token and get AuthToken based on stored ID.
        #
        # @see #encoded
        # @param token [String] JWT encoded hash with AuthToken#id
        # @raise [DecodeError] auth_token_id is missing or no AuthToken found.
        # @return [AuthToken]
        def decode token
          payload = JWT.decode(
            token, config.jwt_secret, config.jwt_algorithm
          ).first

          auth_token = self[payload['auth_token_id']]

          if payload['auth_token_id'].nil?
            raise DecodeError, "auth_token_id missing: #{payload}"
          elsif auth_token.nil?
            raise DecodeError, "auth_token_id not found: #{payload}"
          end

          auth_token
        end

        # Encode a value using jwt_secret and jwt_algorithm.
        #
        # @param value [Hash, Array]
        # @return [String] Encoded value
        def encode value
          JWT.encode value, config.jwt_secret, config.jwt_algorithm
        end

        # Decode a JWT token and get AuthToken based on stored ID. If an open
        # AuthToken is found, update its last_used_at value.
        #
        # @see #decode
        # @param token [String] JWT encoded hash with AuthToken#id
        # @raise [DecodeError] auth_token_id is missing or no AuthToken found.
        # @return [AuthToken]
        def use token
          auth_token = decode token

          if auth_token && !auth_token.expired?
            auth_token.update(last_used_at: Time.now)
            auth_token
          else
            nil
          end
        end

        # @return [Configuration]
        def config
          Jm81auth.config
        end
      end
    end
  end
end
