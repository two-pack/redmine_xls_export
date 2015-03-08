require 'simplecov'
SimpleCov.start do
  add_group "Controllers", "plugins/redmine_xls_export/app/controllers"
  add_group "Views", "plugins/redmine_xls_export/app/views"
  add_group "Config", "plugins/redmine_xls_export/config"
  add_group "Library", "plugins/redmine_xls_export/lib"
  add_group "Test", "plugins/redmine_xls_export/test"
end

require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

require 'capybara/rails'

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

  def click_button_and_wait(name)
    click_button name
    sleep(0.5)
  end

  def click_link_and_wait(name)
    click_link name
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

  def save_exported_xls(name)
    save_exported_file(name, 'xls')
  end

  def save_exported_zip(name)
    save_exported_file(name, 'zip')
  end

  def save_exported_file(name, ext)
    open(name + '.' + ext, 'wb') { |f| f.write page.body }
  end

  def assert_to_export(filename, ext, generated)
    assert_equal 200, page.status_code
    assert_equal 'binary', page.response_headers['Content-Transfer-Encoding']
    if generated
      assert_match /attachment; filename=".{6}_eCookbook_#{filename}\.#{ext}"/,
                   page.response_headers['Content-Disposition']
    else
      assert_match /attachment; filename="#{filename}\.#{ext}"/,
                   page.response_headers['Content-Disposition']
    end
  end

  def uncheck_all_detailed_options
    uncheck 'settings_relations'
    uncheck 'settings_watchers'
    uncheck 'settings_journal'
    uncheck 'settings_attachments'
    uncheck 'settings_query_columns_only'
    uncheck 'settings_group'
    uncheck 'settings_generate_name'
    uncheck 'settings_export_attached'
    uncheck 'settings_separate_journals'
    fill_in 'settings_export_name', :with => 'issues_export'
    fill_in 'settings_issues_limit', :with => '0'
    fill_in 'issues_export_offset', :with => '0'
    fill_in 'settings_export_name', :with => 'issues_export'
  end
end

# for log_user method
if Redmine::VERSION::MAJOR <= 2 then
  module Redmine
    class IntegrationTest < ActionDispatch::IntegrationTest
    end
  end
end