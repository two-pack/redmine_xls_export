source 'https://rubygems.org'

gem "spreadsheet"
gem "nokogiri"

group :export_attachments do
  # If you use Redmine 2.3.x or older, remove rubyzip version and zip-zip.
  gem "rubyzip", ">= 1.1.3"
  gem "zip-zip"
end

group :test do
  gem 'launchy'
  gem 'simplecov', "~> 0.9.1", :require => false
end