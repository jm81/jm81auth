# Based on satellizer example:
# https://github.com/sahat/satellizer/blob/master/examples/server/ruby

module Jm81auth
  module OAuth
    class Base
      # Setup @params from params param (Har, har). Also, set @access_token,
      # either from params Hash, or by calling #get_access_token. @params is the
      # expected params needed by #get_access_token.
      #
      # @param params [Hash]
      #   Expected to contain :code, :redirectUri, :clientId, and, optionally,
      #   :access_token
      def initialize params
        @params = {
          code: params[:code],
          redirect_uri: params[:redirectUri],
          client_id: params[:clientId],
          client_secret: Jm81auth.config.client_secrets[provider_name]
        }

        @access_token = params[:access_token] || get_access_token
      end

      # @return [Hash] Data returned by accessing data URL.
      def data
        @data or get_data
      end

      # @return [String] Display name (e.g. "Jane Doe") from data.
      def display_name
        data['name']
      end

      # @return [String] Email address from data.
      def email
        data['email']
      end

      # Get data via get request to provider's data URL.
      #
      # @return [Hash]
      def get_data
        response = client.get(self.class::DATA_URL, access_token: @access_token)
        @data = JSON.parse(response.body)
      end

      # @return [String] Provider name, based on class name.
      def provider_name
        self.class.name.split('::').last.downcase
      end

      # @return [String] Provider assigned ID, from data.
      def provider_id
        data['id'] || data['sub']
      end

      # @return [Hash] provider_name and provider_id
      def provider_data
        { provider_name: provider_name, provider_id: provider_id }
      end

      private

      # @return [HTTPClient]
      def client
        @client ||= HTTPClient.new
      end
    end
  end
end
