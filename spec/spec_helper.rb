require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'jm81auth'
require 'sequel'
require 'factory_girl'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f}

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true

  config.include FactoryGirl::Syntax::Methods

  config.before :suite do
    FactoryGirl.find_definitions
  end

  config.around :each do |example|
    DB.transaction(rollback: :always, auto_savepoint: true) { example.run }
  end
end

DB = Sequel.sqlite

DB.create_table(:users) do
  primary_key :id
  column :email, "varchar(255)"
  column :display_name, "varchar(255)"
end

DB.create_table(:auth_methods) do
  primary_key :id
  foreign_key :user_id, :users, :on_delete=>:cascade, :on_update=>:cascade
  column :provider_name, "varchar(255)", :null=>false
  column :provider_id, "integer unsigned", :null=>false
end

DB.create_table(:auth_tokens) do
  primary_key :id
  foreign_key :user_id, :users, :on_delete=>:restrict, :on_update=>:cascade
  foreign_key :auth_method_id, :auth_methods, :on_delete=>:restrict, :on_update=>:cascade
  column :created_at, "timestamp", :null=>false
  column :last_used_at, "timestamp", :null=>false
  column :closed_at, "timestamp"
end

Jm81auth.config do |config|
  config.jwt_secret = 'testsecret'
end

class AuthMethod < Sequel::Model
  include Jm81auth::Models::AuthMethod
end

class AuthToken < Sequel::Model
  include Jm81auth::Models::AuthToken
end

class User < Sequel::Model
  include Jm81auth::Models::User
end
