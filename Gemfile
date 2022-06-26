source 'https://rubygems.org'
ruby '2.7.2'

gem 'bootsnap', '>= 1.4.2', require: false
gem 'rails', '~> 6.1.6'

gem 'dotenv-rails', '~> 2.7.6'
gem 'pg', '~> 1.3.5'
gem 'puma', '~> 5.6'
gem 'rack', '~> 2.2.3'
gem 'rack-attack', '~> 6.6.1'
gem 'rack-cors', '~> 1.1.1'
gem 'sidekiq', '~> 6.4.2'
gem 'strong_migrations', '~> 1.0.0'

gem 'nilify_blanks', '~> 1.4'
gem 'ransack', '~> 3.2.1'

# Authentication
gem 'devise', '~> 4.8.1'
gem 'devise_token_auth', '~> 1.2.0'

# Serializing json views
gem 'jb', '~> 0.8.0'

# Pagination
gem 'pagy', '~> 5.10'
gem 'rswag'

group :development, :test do
  gem 'bullet', '~> 7.0.2'
  gem 'byebug', '>= 11.0.1', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails', '~> 6.2.0'
  gem 'faker', '~> 2.21.0'
  gem 'rspec-rails', '~> 5.1.2'
  gem 'rswag-specs'
end

group :development do
  gem 'annotate', '~> 3.2.0'
  gem 'letter_opener', '~> 1.8.1'
  gem 'reek', '~> 6.1.1', require: false
  gem 'rubocop', '~> 1.30.1', require: false
  gem 'rubocop-rails', '~> 2.14.2', require: false
  gem 'rubocop-rspec', '~> 2.11.1', require: false
  gem 'spring', '~> 2.1.1'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'rspec-json_expectations', '~> 2.2.0'
  gem 'shoulda-matchers', '~> 5.1.0'
  gem 'simplecov', '~> 0.21.2'
  gem 'webmock', '~> 3.14.0'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
