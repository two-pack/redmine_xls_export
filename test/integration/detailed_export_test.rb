# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class DetailedExportTest < ActionController::IntegrationTest
  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories, :queries,
           :projects_trackers, :issue_relations, :watchers,
           :roles, :journals, :journal_details, :attachments,
           :member_roles,
           :members,
           :enabled_modules,
           :workflows,
           :custom_values

  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/',
                                         [:custom_fields, :custom_fields_projects, :custom_fields_trackers])

  def uncheck_all_options
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
  end

  def setup
    login_with_admin
    show_detailed_page
    uncheck_all_options
  end

  def teardown
    logout
  end

  def assert_columns_options(option)
    show_detailed_page
    uncheck_all_options

    check option
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'xls', false
  end

  def test_to_export_with_relations
    assert_columns_options 'settings_relations'
  end

  def test_to_export_with_watchers
    assert_columns_options 'settings_watchers'
  end

  def test_to_export_with_journals
    assert_columns_options 'settings_journal'
  end

  def test_to_export_with_list_attachments
    assert_columns_options 'settings_attachments'
  end

  def assert_extra_options(option)
    check option
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'zip', false
  end

  def test_to_export_with_attachments
    assert_extra_options 'settings_export_attached'
  end

  def test_to_export_with_separated_journals
    assert_extra_options 'settings_separate_journals'
  end

end