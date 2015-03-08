# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class QuickExportTest < Redmine::IntegrationTest
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

  def prepare_export_configure_with_check(settings)
    login_with_admin

    show_configure_page
    settings.each do |key, value|
      case value
        when TrueClass, FalseClass
          value == true ? check(key) : uncheck(key)
        when String
          fill_in key, :with => value
      end
    end
    click_button_and_wait 'Apply'

    logout
  end

  def assert_quick_export(filename, ext, generated = true)
    visit '/projects/ecookbook/issues'
    assert_not_nil page

    click_link 'Quick'
    assert_to_export filename, ext, generated
  end


  def setup
  end

  def teardown
  end

  def test_quick_link_is_in_issues_page
    visit '/projects/ecookbook/issues'
    assert_not_nil page
    assert has_link?('Quick')
  end

  def test_to_export_xls_file
    prepare_export_configure_with_check(
        { 'settings_export_attached' => false,
          'settings_separate_journals' => false,
          'settings_generate_name' => true,
          'settings_export_name' => 'issues_export' })
    assert_quick_export('issues_export', 'xls')
  end

  def test_to_export_xls_file_without_generate_name
    prepare_export_configure_with_check(
        { 'settings_export_attached' => false,
          'settings_separate_journals' => false,
          'settings_generate_name' => false,
          'settings_export_name' => 'test_export' })
    assert_quick_export('test_export', 'xls', false)
  end

  def test_to_export_zip_file_for_attached
    prepare_export_configure_with_check(
        { 'settings_export_attached' => true,
          'settings_separate_journals' => false,
          'settings_generate_name' => true,
          'settings_export_name' => 'issues_export' })
    assert_quick_export('issues_export', 'zip')
  end

  def test_to_export_zip_file_for_separating_journals
    prepare_export_configure_with_check(
        { 'settings_export_attached' => false,
          'settings_separate_journals' => true,
          'settings_generate_name' => true,
          'settings_export_name' => 'issues_export' })
    assert_quick_export('issues_export', 'zip')
  end

  def test_to_export_zip_file_with_strip_html_tags
    prepare_export_configure_with_check(
        { 'settings_export_attached' => false,
          'settings_separate_journals' => true,
          'settings_generate_name' => true,
          'settings_strip_html_tags' => true,
          'settings_export_name' => 'issues_export' })
    assert_quick_export('issues_export', 'zip')
  end
end