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
    visit '/settings/plugin/redmine_xls_export'
    assert_not_nil page
  end

  def test_to_show_configure_page_by_administrator
    assert page.has_css?('h2', text: ' » Issues XLS export')
  end

  def test_to_set_default_values_of_columns_options
    assert_equal page.has_checked_field?('settings_relations'), true
    assert_equal page.has_checked_field?('settings_watchers'), true
    assert_equal page.has_checked_field?('settings_journal'), false
    assert_equal page.has_checked_field?('settings_attachments'), false
  end

  def test_to_set_default_values_of_export_options
    assert_equal page.has_checked_field?('settings_query_columns_only'), false
    assert_equal page.has_checked_field?('settings_group'), false
    assert_equal page.has_checked_field?('settings_generate_name'), true
  end

  def test_to_set_default_values_of_extra_options
    assert_equal page.has_checked_field?('settings_export_attached'), false
    assert_equal page.has_checked_field?('settings_separate_journals'), false
  end

  def test_to_set_default_values_of_date_format_options
    assert page.has_field?('settings_created_format', :with => 'dd.mm.yyyy hh:mm:ss')
    assert page.has_field?('settings_updated_format', :with => 'dd.mm.yyyy hh:mm:ss')
    assert page.has_field?('settings_start_date_format', :with => 'dd.mm.yyyy')
    assert page.has_field?('settings_due_date_format', :with => 'dd.mm.yyyy')
  end

  def test_to_set_default_values_of_other_options
    assert page.has_field?('settings_issues_limit', :with => '0')
    assert page.has_field?('settings_export_name', :with => 'issues_export')
  end

  def test_not_to_show_issue_export_offset_setting
    assert page.has_no_selector?('input#issues_export_offset')
  end

  def teardown
    logout
  end
end