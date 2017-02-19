$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "jm81auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'jm81auth'
  s.version     = Jm81auth::VERSION
  s.authors     = ['Jared Morgan']
  s.email       = ['jmorgan@mchost.net']
  s.homepage    = 'https://github.com/jm81/jm81auth'
  s.summary     = 'An authentication library for Rails API'
  s.description = 'I have no excuse for giving the world yet another auth lib.'
  s.license     = 'MIT'

  s.files = Dir["lib/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'httpclient', '~> 2.6.0.1'
  s.add_dependency 'jwt', '~> 1.5.1'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'factory_girl', '~> 4.0'
  s.add_development_dependency 'sequel', '~> 4.0'
  s.add_development_dependency 'sqlite3', '~> 1.3'
  s.add_development_dependency 'rspec', '~> 3.2'
end
