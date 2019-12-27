module Jm81auth
  module OAuth
    class Google < Base
      ACCESS_TOKEN_URL = 'https://oauth2.googleapis.com/token'
      DATA_URL = 'https://www.googleapis.com/oauth2/v3/userinfo'

      def get_access_token
        response = client.post(
          ACCESS_TOKEN_URL, @params.merge(grant_type: 'authorization_code')
        )

        JSON.parse(response.body)['access_token']
      end
    end
  end
end

