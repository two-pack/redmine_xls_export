require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

require 'capybara/rails'
class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL
end
