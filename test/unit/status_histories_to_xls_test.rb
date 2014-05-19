require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

require File.expand_path(File.dirname(__FILE__) + '/../../lib/xls_export')

class StatusHistoriesToXlsTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :journals, :journal_details, :issue_statuses

  include Redmine::I18n
  include Redmine::Export::XLS

  def setup

  end

  def teardown
    # Do nothing
  end

  def test_sheet_name_is_valid
    book, sheet = init_status_histories_book()

    assert_not_nil book
    assert_not_nil sheet
    assert_equal 'Status histories', book.worksheet(0).name
    assert_equal 'Status histories', sheet.name
  end

  def test_to_add_columns_header
    book, sheet = init_status_histories_book()
    columns_width = add_columns_header_for_status_histories(sheet)

    header = ['#', l(:field_project), l(:plugin_xlse_field_status_updated_created_on), l(:field_status)]
    row = sheet.row(0)
    i = 0
    header.each do |h|
      assert_equal h, row[i]
      assert columns_width[i] > 0
      i = i + 1
    end
  end

  def test_to_set_default_format_for_columns
    book, sheet = init_status_histories_book()
    columns_width = add_columns_header_for_status_histories(sheet)
    set_columns_default_format(sheet, {:updated_format => 'dd.mm.yyyy hh:mm:ss'})

    assert_equal '0', sheet.column(0).default_format.number_format
    assert_equal 'GENERAL', sheet.column(1).default_format.number_format
    assert_equal 'dd.mm.yyyy hh:mm:ss', sheet.column(2).default_format.number_format
    assert_equal 'GENERAL', sheet.column(4).default_format.number_format
  end

  def test_to_export_status_histories
    book, sheet = init_status_histories_book()
    columns_width = add_columns_header_for_status_histories(sheet)
    set_columns_default_format(sheet, {:updated_format => 'dd.mm.yyyy hh:mm:ss'})

    extract_status_histories(sheet, columns_width, Issue.find(:all))

    # row 1
    assert_equal 1, sheet.row(1)[0]
    assert_equal 'eCookbook', sheet.row(1)[1]
    assert_equal Journal.find(1).created_on, sheet.row(1)[2]
    assert_equal 'Assigned', sheet.row(1)[3]

    columns_width.each do |width|
      assert width > 0
    end
  end
end