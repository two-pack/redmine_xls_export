# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ConfigurePageTest < ActionController::IntegrationTest
  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories, :queries,
           :projects_trackers,
           :roles,
           :member_roles,
           :members,
           :enabled_modules,
           :workflows,
           :custom_values

  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/',
                                         [:custom_fields, :custom_fields_projects, :custom_fields_trackers])

  def login_with_admin
    visit '/'
    click_link 'Sign in'
    assert page.has_link?("Lost password")

    fill_in 'username', with: 'admin'
    fill_in 'password', with: 'admin'
    click_button 'Login'
    assert page.has_link?("Sign out")
  end

  def logout
    visit '/'
    click_link 'Sign out'
    assert page.has_link?("Sign in")
  end


  def setup
    login_with_admin
  end

  def test_to_show_configure_page_by_administrator
    visit '/settings/plugin/redmine_xls_export'
    assert_not_nil page
    assert page.has_css?('h2', text: ' » Issues XLS export')
  end

  def teardown
    logout
  end
end