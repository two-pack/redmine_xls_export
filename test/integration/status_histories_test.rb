# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class StatusHistoriesTest < Redmine::IntegrationTest
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
  end

  def teardown
    logout
  end

  def test_to_show_setting_on_configure_page
    show_configure_page

    assert page.has_css?('label.floating', text: 'Export status histories')
    assert page.has_selector?('label.floating input#settings_export_status_histories')
  end

  def test_setting_default_on_configure_page
    show_configure_page

    assert_equal false, page.has_checked_field?('settings_export_status_histories')
  end

  def test_to_export_zip_with_status_histories
    show_detailed_page
    uncheck_all_detailed_options

    check 'settings_export_status_histories'
    click_button_and_wait 'Export'

    assert_to_export 'issues_export', 'zip', false
  end
end