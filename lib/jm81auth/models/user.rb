module Jm81auth
  module Models
    module User
      EMAIL_REGEX = /.@./

      def self.included(base)
        base.extend ClassMethods

        base.class_eval do
          if respond_to? :has_many
            has_many :auth_methods
            has_many :auth_tokens
          else
            one_to_many :auth_methods
            one_to_many :auth_tokens
          end
        end
      end

      module ClassMethods
        # Find user by email address. Returns nil if the email address is not
        # valid (for a minimal version of valid)
        #
        # @param email [~to_s] Email Address
        # @return [User, nil]
        def find_by_email email
          if email.to_s =~ EMAIL_REGEX
            where(email: email.to_s.downcase.strip).first
          else
            nil
          end
        end

        # Login from OAuth.
        #
        # First try to find an AuthMethod matching the provider data. If none,
        # find or create a User based on email, then create an AuthMethod.
        # Finally, create and return an AuthToken.
        #
        # @param oauth [OAuth::Base]
        #   OAuth login object, include #provider_data (Hash with provider_name
        #   and provider_id), #email and #display_name.
        # @return [AuthToken]
        def oauth_login oauth
          method = ::AuthMethod.by_provider_data oauth.provider_data

          if !method
            user = find_by_email(oauth.email) || create(
              email: oauth.email.downcase,
              display_name: oauth.display_name
            )

            method = user.add_auth_method oauth.provider_data
          end

          method.create_token
        end
      end
    end
  end
end
