module Jm81auth
  module OAuth
    class Facebook < Base
      ACCESS_TOKEN_URL = 'https://graph.facebook.com/oauth/access_token'
      DATA_URL = 'https://graph.facebook.com/me'

      def get_access_token
        response = client.post(ACCESS_TOKEN_URL, @params)
        JSON.parse(response.body)['access_token']
      end

      def get_data
        response = client.get(
          self.class::DATA_URL, access_token: @access_token,
          fields: 'id,name,email'
        )
        @data = JSON.parse(response.body)
      end
    end
  end
end
