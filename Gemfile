source 'https://rubygems.org'
ruby file: '.ruby-version'

gem 'bootsnap', '~> 1.18', require: false
gem 'rails', '~> 7.2.2'

gem 'dotenv-rails', '~> 3.1'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.5'
gem 'rack-attack', '~> 6.7'
gem 'rack-cors', '~> 2.0'
gem 'sidekiq', '~> 7.3'
gem 'strong_migrations', '~> 2.1'

gem 'nilify_blanks', '~> 1.4'

# Authentication
gem 'devise', '~> 4.9'
gem 'devise_token_auth', '~> 1.2.5'

# Serializing json views
gem 'jb', '~> 0.8.2'

# Pagination
gem 'pagy', '~> 5.10'
gem 'rswag-api', '~> 2.16'
gem 'rswag-ui', '~> 2.16'
# rswag-ui requires ostruct, which leaves Ruby's default gems in 4.0.
gem 'ostruct', '~> 0.6'

group :development, :test do
  gem 'bullet', '~> 8.0'
  gem 'debug', '~> 1.10', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.5'
  gem 'rspec-rails', '~> 7.1'
  gem 'rswag-specs', '~> 2.16'
end

group :development do
  gem 'annotate', '~> 3.2'
  gem 'letter_opener', '~> 1.10'
  gem 'reek', '~> 6.3', require: false
  gem 'rubocop', '~> 1.69', require: false
  gem 'rubocop-factory_bot', '~> 2.26', require: false
  gem 'rubocop-rails', '~> 2.27', require: false
  gem 'rubocop-rspec', '~> 3.2', require: false
  gem 'rubocop-rspec_rails', '~> 2.30', require: false
end

group :test do
  gem 'rspec-json_expectations', '~> 2.2'
  gem 'shoulda-matchers', '~> 6.4'
  gem 'simplecov', '~> 0.22'
  gem 'webmock', '~> 3.24'
end

gem 'tzinfo-data', platforms: %i[windows jruby]
