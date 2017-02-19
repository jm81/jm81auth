require 'spec_helper'

RSpec.describe User, type: :model do
  subject(:user) { FactoryGirl.build(:user) }

  it { is_expected.to be_valid }

  describe '#auth_methods' do
    before(:each) { user.save }

    let!(:auth_method) do
      user.add_auth_method provider_name: :test, provider_id: 1
    end

    it 'has many' do
      expect(auth_method).to be_a(AuthMethod)
      expect(user.auth_methods).to eq([auth_method])
      expect(AuthMethod[auth_method.id].user).to eq(user)
    end

    it 'cascades deletes' do
      user.destroy
      expect(AuthMethod[auth_method.id]).to be(nil)
    end
  end

  describe '#auth_tokens' do
    before(:each) { user.save }

    let!(:auth_token) do
      user.add_auth_token(
        auth_method: FactoryGirl.create(:auth_method), last_used_at: Time.now
      )
    end

    it 'has many' do
      expect(auth_token).to be_a(AuthToken)
      expect(user.auth_tokens).to eq([auth_token])
      expect(AuthToken[auth_token.id].user).to eq(user)
    end

    it 'restricts deletes' do
      expect { user.destroy }.
        to raise_error(Sequel::ForeignKeyConstraintViolation)
    end
  end

  describe '.find_by_email' do
    let!(:existing) { FactoryGirl.create(:user, email: 'test@example.com') }

    context 'existing User with given email' do
      it 'gets existing User' do
        expect(User.find_by_email('test@example.com')).to eq(existing)
        expect(User.find_by_email('  test@example.com ')).to eq(existing)
        expect(User.find_by_email('TEST@example.com')).to eq(existing)
      end
    end

    context 'no existing User with given email' do
      it 'is nil' do
        expect(User).to receive(:where).twice.and_call_original
        expect(User.find_by_email('other@example.com')).to be(nil)
        expect(User.find_by_email('test@example.org')).to be(nil)
      end
    end

    context 'nil email' do
      it 'is nil' do
        expect(User).to_not receive(:where)
        expect(User.find_by_email(nil)).to be(nil)
      end
    end

    context 'invalid email' do
      it 'is nil' do
        expect(User).to_not receive(:where)
        expect(User.find_by_email('')).to be(nil)
        expect(User.find_by_email('@example.com')).to be(nil)
        expect(User.find_by_email('test')).to be(nil)
      end
    end
  end

  describe '.oauth_login' do
    let(:oauth) { double 'Jm81auth::OAuth' }

    let!(:user) do
      FactoryGirl.create :user, email: 'existing-user@example.com',
        display_name: 'Existing User'
    end

    let!(:auth_method) do
      FactoryGirl.create :auth_method,
        user: user, provider_name: 'github', provider_id: 5
    end

    def login
      @login_token = User.oauth_login oauth
      @login_user = @login_token.user
      @login_method = @login_token.auth_method
      user.reload
      auth_method.reload
    end

    context 'existing AuthMethod' do
      before(:each) do
        expect(oauth).to_not receive(:email)

        expect(oauth).to receive(:provider_data) do
          { provider_name: 'github', provider_id: 5 }
        end
      end

      it 'uses existing (does not create) User' do
        expect { login }.to_not change(User, :count)
        expect(@login_user.id).to eq(user.id)
        expect(@login_user.email).to eq('existing-user@example.com')
        expect(@login_user.display_name).to eq('Existing User')
      end

      it 'uses existing (does not create) AuthMethod' do
        expect { login }.to_not change(AuthMethod, :count)
        expect(@login_method.id).to eq(auth_method.id)
      end

      it 'creates and returns AuthToken' do
        expect { login }.to change(AuthToken, :count).by(1)
        expect(@login_token.user.id).to eq(user.id)
        expect(@login_token.auth_method.id).to eq(auth_method.id)
        expect(@login_token.last_used_at).to be_a(Time)
      end
    end

    context 'no existing AuthMethod' do
      before(:each) do
        expect(oauth).to receive(:provider_data).twice do
          { provider_name: 'github', provider_id: 10 }
        end
      end

      context 'User found with same email' do
        before(:each) do
          expect(oauth).to receive(:email) { 'existing-user@example.com' }
        end

        it 'uses existing (does not create) a new User' do
          expect { login }.to_not change(User, :count)
          expect(@login_user.id).to eq(user.id)
          expect(@login_user.email).to eq('existing-user@example.com')
          expect(@login_user.display_name).to eq('Existing User')
        end

        it 'creates a new AuthMethod' do
          expect { login }.to change(AuthMethod, :count).by(1)
          expect(auth_method.provider_id).to eq(5)
          expect(@login_method.id).to_not eq(auth_method.id)
          expect(@login_method.provider_name).to eq('github')
          expect(@login_method.provider_id).to eq(10)
          expect(@login_method.user.id).to eq(user.id)
        end

        it 'creates and returns AuthToken' do
          expect { login }.to change(AuthToken, :count).by(1)
          expect(@login_token.user.id).to eq(user.id)
          expect(@login_token.auth_method.id).to eq(@login_method.id)
          expect(@login_token.last_used_at).to be_a(Time)
        end
      end

      context 'No User found with valid OAuth email' do
        before(:each) do
          expect(oauth).to receive(:email).twice { 'new-user@example.com' }
          expect(oauth).to receive(:display_name) { 'New Name' }
        end

        it 'creates a new User' do
          expect { login }.to change(User, :count).by(1)
          expect(user.display_name).to eq('Existing User')
          expect(@login_user.email).to eq('new-user@example.com')
          expect(@login_user.display_name).to eq('New Name')
        end

        it 'creates a new AuthMethod' do
          expect { login }.to change(AuthMethod, :count).by(1)
          expect(auth_method.provider_id).to eq(5)
          expect(@login_method.id).to_not eq(auth_method.id)
          expect(@login_method.provider_name).to eq('github')
          expect(@login_method.provider_id).to eq(10)
          expect(@login_method.user.id).to eq(@login_user.id)
        end

        it 'creates and returns AuthToken' do
          expect { login }.to change(AuthToken, :count).by(1)
          expect(@login_token.user.id).to eq(@login_user.id)
          expect(@login_token.auth_method.id).to eq(@login_method.id)
          expect(@login_token.last_used_at).to be_a(Time)
        end
      end

      context 'OAuth email is empty' do
        before(:each) do
          user.update email: ''
          expect(oauth).to receive(:email).twice { '' }
          expect(oauth).to receive(:display_name) { 'New Name' }
        end

        it 'creates a new User' do
          expect { login }.to change(User, :count).by(1)
          expect(user.display_name).to eq('Existing User')
          expect(@login_user.email).to eq('')
          expect(@login_user.display_name).to eq('New Name')
        end

        it 'creates a new AuthMethod' do
          expect { login }.to change(AuthMethod, :count).by(1)
          expect(auth_method.provider_id).to eq(5)
          expect(@login_method.id).to_not eq(auth_method.id)
          expect(@login_method.provider_name).to eq('github')
          expect(@login_method.provider_id).to eq(10)
          expect(@login_method.user.id).to eq(@login_user.id)
        end

        it 'creates and returns AuthToken' do
          expect { login }.to change(AuthToken, :count).by(1)
          expect(@login_token.user.id).to eq(@login_user.id)
          expect(@login_token.auth_method.id).to eq(@login_method.id)
          expect(@login_token.last_used_at).to be_a(Time)
        end
      end

      context 'OAuth email is invalid' do
        before(:each) do
          user.update email: 'invalid'
          expect(oauth).to receive(:email).twice { 'invalid' }
          expect(oauth).to receive(:display_name) { 'New Name' }
        end

        it 'creates a new User' do
          expect { login }.to change(User, :count).by(1)
          expect(user.display_name).to eq('Existing User')
          expect(@login_user.email).to eq('invalid')
          expect(@login_user.display_name).to eq('New Name')
        end

        it 'creates a new AuthMethod' do
          expect { login }.to change(AuthMethod, :count).by(1)
          expect(auth_method.provider_id).to eq(5)
          expect(@login_method.id).to_not eq(auth_method.id)
          expect(@login_method.provider_name).to eq('github')
          expect(@login_method.provider_id).to eq(10)
          expect(@login_method.user.id).to eq(@login_user.id)
        end

        it 'creates and returns AuthToken' do
          expect { login }.to change(AuthToken, :count).by(1)
          expect(@login_token.user.id).to eq(@login_user.id)
          expect(@login_token.auth_method.id).to eq(@login_method.id)
          expect(@login_token.last_used_at).to be_a(Time)
        end
      end
    end
  end
end
