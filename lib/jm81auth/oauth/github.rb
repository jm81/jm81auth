module Jm81auth
  module OAuth
    class Github < Base
      ACCESS_TOKEN_URL = 'https://github.com/login/oauth/access_token'
      DATA_URL = 'https://api.github.com/user'

      def get_access_token
        response = client.post(ACCESS_TOKEN_URL, @params)
        Rack::Utils.parse_nested_query(response.body)['access_token']
      end
    end
  end
end
