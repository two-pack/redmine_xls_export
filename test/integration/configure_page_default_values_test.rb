# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ConfigurePageDefaultValuesTest < ActionController::IntegrationTest
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

  def setup
    login_with_admin
    show_configure_page
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
    assert page.has_field?('settings_closed_date_format', :with => 'dd.mm.yyyy hh:mm:ss')
  end

  def test_to_set_default_values_of_other_options
    assert page.has_field?('settings_issues_limit', :with => '0')
    assert page.has_field?('settings_export_name', :with => 'issues_export')
  end

  def teardown
    logout
  end
end