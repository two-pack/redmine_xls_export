require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

require 'capybara/rails'
class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  def click_button_and_wait(name)
    click_button name
    sleep(0.5)
  end

  def login(user, password)
    visit '/'
    click_link 'Sign in'
    assert page.has_link?("Lost password")

    fill_in 'username', with: user
    fill_in 'password', with: password
    click_button 'Login'
    assert page.has_link?("Sign out")
  end

  def login_with_admin
    login 'admin', 'admin'
  end

  def login_with_user
    login 'jsmith', 'jsmith'
  end

  def logout
    visit '/'
    click_link 'Sign out'
    assert page.has_link?("Sign in")
  end

  def show_configure_page
    visit '/settings/plugin/redmine_xls_export'
    assert_not_nil page
  end

  def show_detailed_page
    visit '/projects/ecookbook/issues_xls_export'
    assert_not_nil page
  end

end
