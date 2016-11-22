source 'http://rubygems.org'

ruby '2.2.3'
#ruby-gemset=railstutorial_rails_4_0

gem 'rake', '11.1.2'

#gem 'coffee-script-source', '1.10.0'
gem 'coffee-script-source', '1.8.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5'

gem 'acts-as-taggable-on', '~> 3.4'
gem 'shortener'

gem 'kaminari'
gem 'kaminari-bootstrap', '~> 3.0.1'

gem "rails-bootstrap-helpers"

gem 'bootstrap-sass', '2.3.2.0'
gem 'anjlab-bootstrap-rails', :require => 'bootstrap-rails', :github => 'anjlab/bootstrap-rails'
#gem 'font-awesome-rails'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

group :development, :test do
#  gem 'sqlite3'
  gem 'rspec-rails', '2.13.1'
end

gem 'redis'
gem 'redis-objects'

gem 'slim-rails'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

gem 'omniauth', '1.2.2'
gem 'omniauth-oauth2', '1.3.1'
# gem "omniauth-coub" , '0.0.2'
gem "omniauth-coub"

gem "faraday"

gem 'russian', '~> 0.6.0'

gem 'coub_api'

gem 'rest-client'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
#gem 'sdoc', '~> 0.4.0', group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

gem "gritter", "1.2.0"

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  gem 'spork-rails', '4.0.0'
  gem 'guard-spork', '2.1.0'
  gem 'childprocess', '0.3.6'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :doc do
  gem 'sdoc', '0.4.0', require: false
end

group :production do
  gem 'pg', '0.15.1'
  gem 'rails_12factor', '0.0.2'
end

gem 'test-unit'

gem 'minitest'

group :test do
  gem 'selenium-webdriver', '2.35.1'
  gem 'capybara', '2.1.0'

  gem 'rb-notifu', '0.0.4'
  gem 'win32console', '1.3.2'
#  gem 'wdm', '0.1.0'
  gem 'wdm'
end
