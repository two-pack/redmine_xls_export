# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class DetailedExportTest < Redmine::IntegrationTest
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

  def setup
    login_with_admin
    show_detailed_page
    uncheck_all_detailed_options
  end

  def teardown
    logout
  end

  def assert_columns_options(option)
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

  def test_to_exoprt_with_date_format_options
    fill_in 'settings_created_format', :with => 'yyyy/mm/dd hh:mm:ss'
    fill_in 'settings_updated_format', :with => 'yyyy.mm.dd hh:mm:ss'
    fill_in 'settings_start_date_format', :with => 'yyyy/mm/dd'
    fill_in 'settings_due_date_format', :with => 'yyyy.mm.dd'
    fill_in 'settings_closed_date_format', :with => 'yyyy-mm-dd'
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'xls', false
  end

  def test_to_export_with_overlimit_default
    fill_in 'settings_issues_limit', :with => '0'
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'xls', false
  end

  def test_to_export_with_overlimit_5
    fill_in 'settings_issues_limit', :with => '5'
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'xls', false
  end

  def test_to_export_with_offset_5
    fill_in 'issues_export_offset', :with => '5'
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'xls', false
  end

  def test_to_export_with_nongenerated_name
    uncheck 'settings_generate_name'
    fill_in 'settings_export_name', :with => 'test'
    click_button_and_wait 'Export'
    assert_to_export 'test', 'xls', false
  end

  def test_to_export_with_generated_name
    check 'settings_generate_name'
    fill_in 'settings_export_name', :with => 'test'
    click_button_and_wait 'Export'
    assert_to_export 'test', 'xls', true
  end

  def test_to_export_with_strip_html_tags
    uncheck 'settings_generate_name'
    check 'settings_strip_html_tags'
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'xls', false
  end

  def assert_export_options(option, generated = false)
    check option
    click_button_and_wait 'Export'
    assert_to_export 'issues_export', 'xls', generated
  end

  def test_to_export_selected_columns_only
    assert_export_options 'settings_query_columns_only'
  end

  def test_to_export_with_splitting_by_grouping_criteria
    visit '/projects/ecookbook/issues?group_by=tracker'
    click_link_and_wait('Detailed')
    uncheck_all_detailed_options
    assert_export_options 'settings_group'
  end

  def test_to_export_with_suggested_name
    assert_export_options 'settings_generate_name', true
  end

end