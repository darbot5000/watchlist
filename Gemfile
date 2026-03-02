source "https://rubygems.org"

ruby "~> 3.3"

gem "rails", "~> 8.0"
gem "sqlite3", "~> 2.1"
gem "puma", ">= 5.0"
gem "propshaft"
gem "tailwindcss-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "httparty"
gem "dotenv-rails"
gem "pagy"
gem "image_processing", ">= 1.2"
gem "active_storage_validations"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "dockerfile-rails", ">= 1.6"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
