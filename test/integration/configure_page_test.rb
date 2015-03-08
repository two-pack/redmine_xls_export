# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ConfigurePageTest < Redmine::IntegrationTest
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

  def test_to_show_configure_page_by_administrator
    assert page.has_css?('h2', text: 'Issues XLS export')
  end

  def test_not_to_show_issue_export_offset_setting
    assert page.has_no_selector?('input#issues_export_offset')
  end


  def test_to_change_values_of_columns_options
    uncheck 'settings_relations'
    uncheck 'settings_watchers'
    check 'settings_journal'
    check 'settings_attachments'
    click_button_and_wait 'Apply'

    show_configure_page
    assert_changed_columns_options

    show_detailed_page
    assert_changed_columns_options
  end

  def assert_changed_columns_options
    assert_equal page.has_checked_field?('settings_relations'), false
    assert_equal page.has_checked_field?('settings_watchers'), false
    assert_equal page.has_checked_field?('settings_journal'), true
    assert_equal page.has_checked_field?('settings_attachments'), true
  end

  def test_to_change_values_of_export_options
    check 'settings_query_columns_only'
    check 'settings_group'
    uncheck 'settings_generate_name'
    click_button_and_wait 'Apply'

    show_configure_page
    assert_changed_export_options

    show_detailed_page
    assert_changed_export_options
  end

  def assert_changed_export_options
    assert_equal page.has_checked_field?('settings_query_columns_only'), true
    assert_equal page.has_checked_field?('settings_group'), true
    assert_equal page.has_checked_field?('settings_generate_name'), false
  end

  def test_to_change_values_of_extra_options
    check 'settings_export_attached'
    check 'settings_separate_journals'
    click_button_and_wait 'Apply'

    show_configure_page
    assert_changed_extra_options

    show_detailed_page
    assert_changed_extra_options
  end

  def assert_changed_extra_options
    assert_equal page.has_checked_field?('settings_export_attached'), true
    assert_equal page.has_checked_field?('settings_separate_journals'), true
  end

  def test_to_change_values_of_date_format_options
    fill_in 'settings_created_format', :with => 'aaaaa'
    fill_in 'settings_updated_format', :with => 'bbbbb'
    fill_in 'settings_start_date_format', :with => 'ccccc'
    fill_in 'settings_due_date_format', :with => 'ddddd'
    fill_in 'settings_closed_date_format', :with => 'eeeee'
    click_button_and_wait 'Apply'

    show_configure_page
    assert_changed_date_format_options

    show_detailed_page
    assert_changed_date_format_options
  end

  def assert_changed_date_format_options
    assert page.has_field?('settings_created_format', :with => 'aaaaa')
    assert page.has_field?('settings_updated_format', :with => 'bbbbb')
    assert page.has_field?('settings_start_date_format', :with => 'ccccc')
    assert page.has_field?('settings_due_date_format', :with => 'ddddd')
    assert page.has_field?('settings_closed_date_format', :with => 'eeeee')
  end

  def test_to_change_values_of_other_options
    fill_in 'settings_issues_limit', :with => '100'
    fill_in 'settings_export_name', :with => 'test_suffix'
    click_button_and_wait 'Apply'

    show_configure_page
    assert_changed_other_options

    show_detailed_page
    assert_changed_other_options
  end

  def assert_changed_other_options
    assert page.has_field?('settings_issues_limit', :with => '100')
    assert page.has_field?('settings_export_name', :with => 'test_suffix')
  end

  def teardown
    logout
  end
end