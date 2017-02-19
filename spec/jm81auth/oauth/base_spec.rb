require 'spec_helper'

module SpecModels
  class OAuthProvider < Jm81auth::OAuth::Base
    DATA_URL = 'https://example.org/data'

    def get_access_token
    end
  end
end

RSpec.describe Jm81auth::OAuth::Base do
  let(:model) { SpecModels::OAuthProvider }

  subject(:oauth) do
    model.new access_token: 'TEST'
  end

  let(:data) do
    {
      'id' => '123',
      'sub' => '456',
      'email' => 'first.last@example.com',
      'name' => 'First Last'
    }
  end

  let(:json_data) do
    <<-EOJSON
      {
        "id": "123",
        "sub": "456",
        "email": "first.last@example.com",
        "name": "First Last"
      }
    EOJSON
  end

  let(:http_response) do
    mock_response = double('http_response')
    allow(mock_response).to receive(:body).and_return(json_data)
    mock_response
  end

  before(:each) do
    allow_any_instance_of(HTTPClient).to receive(:get) { http_response }
  end

  describe '#initialize' do
    let(:params_hash) do
      {
        code: 'CODE',
        redirectUri: 'https://example.org/redirect',
        clientId: 'CLIENT_ID',
        other: 'OTHER',
        access_token: 'ACCESS_TOKEN'
      }
    end

    it 'set @params' do
      new_oauth = Jm81auth::OAuth::Base.new(params_hash)

      expect(new_oauth.instance_variable_get(:@params)).to eq({
        code: 'CODE',
        redirect_uri: 'https://example.org/redirect',
        client_id: 'CLIENT_ID',
        client_secret: nil
      })
    end

    context 'params includes access_token' do
      it 'sets @access_token from params' do
        expect_any_instance_of(model).to_not receive(:get_access_token)
        new_oauth = model.new(params_hash)
        expect(new_oauth.instance_variable_get(:@access_token)).
          to eq('ACCESS_TOKEN')
      end
    end

    context 'params does not include access_token' do
      it 'set access_token using get_access_token' do
        expect_any_instance_of(model).
          to receive(:get_access_token).and_return('123abc')
        new_oauth = model.new(params_hash.merge(access_token: nil))
        expect(new_oauth.instance_variable_get(:@access_token)).
          to eq('123abc')
      end
    end
  end

  describe 'data' do
    context '@data set' do
      let(:set_data) do
        data.merge('email' => 'other@example.com')
      end

      before(:each) { oauth.instance_variable_set(:@data, set_data) }

      it 'returns @data' do
        expect(oauth).to_not receive(:get_data)
        expect(oauth.data).to eq(set_data)
      end
    end

    context '@data not set' do
      it 'sets @data using get_data' do
        expect(oauth).to receive(:get_data).and_call_original
        oauth.data
      end

      it 'returns @data' do
        expect(oauth.data).to eq(data)
      end
    end
  end

  describe '#display_name' do
    it "gets data['name']" do
      expect(oauth.display_name).to eq('First Last')
    end
  end

  describe '#email' do
    it "gets data['email']" do
      expect(oauth.email).to eq('first.last@example.com')
    end
  end

  describe '#get_data' do
    it 'gets data from provider' do
      expect_any_instance_of(HTTPClient).to receive(:get) { http_response }
      expect(oauth.get_data).to eq(data)
    end
  end

  describe '#provider_name' do
    it 'gets provider name based on the class name' do
      expect(oauth.provider_name).to eq('oauthprovider')
      expect(Jm81auth::OAuth::Base.new(access_token: 'a').provider_name).
        to eq('base')
    end
  end

  describe 'provider_id' do
    context "data['id'] is set" do
      it "is data['id']" do
        expect(oauth.provider_id).to eq('123')
      end
    end

    context "data['id'] is not set" do
      before(:each) do
        expect(http_response).
          to receive(:body).and_return(json_data.gsub(/id/, 'no_id'))
      end

      it "is data['sub']" do
        expect(oauth.provider_id).to eq('456')
      end
    end
  end

  describe 'provider_data' do
    it 'is a hash with provider_name and provider_id' do
      expect(oauth.provider_data).to eq({
        provider_name: 'oauthprovider',
        provider_id: '123'
      })
    end
  end
end
