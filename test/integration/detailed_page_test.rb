# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class DetailedPageTest < Redmine::IntegrationTest
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
    login_with_user
    visit '/projects/ecookbook/issues_xls_export'
    assert_not_nil page
  end

  def test_detailed_link_is_in_issues_page
    visit '/projects/ecookbook/issues'
    assert_not_nil page
    assert has_link?('Detailed')
  end

  def test_to_show_issue_export_offset_setting
    assert page.has_selector?('input#issues_export_offset')
  end

  def test_to_back_issues_page
    visit '/projects/ecookbook/issues'
    assert_not_nil page
    click_link 'Tracker'
    assert has_selector?('th a.sort', :text => 'Tracker')

    show_detailed_page
    assert has_link?('Back')

    click_link 'Back'
    assert has_selector?('th a.sort', :text => 'Tracker')
  end

  def teardown
    logout
  end
end