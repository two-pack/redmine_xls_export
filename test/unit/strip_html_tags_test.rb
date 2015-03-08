require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

require File.expand_path(File.dirname(__FILE__) + '/../../lib/xls_export')

class StripHTMLTagsTest < ActiveSupport::TestCase
  include Redmine::Export::XLS::StripHTML

  def setup

  end

  def teardown
    # Do nothing
  end

  def test_no_html_tags_with_strip_setting
    body = "test1\ntest2"
    options = {:strip_html_tags => '1'}

    assert_equal "test1\ntest2", strip_html(body, options)
  end

  def test_no_html_tags_without_strip_setting
    body = "test1\ntest2"
    options = {:strip_html_tags => '0'}

    assert_equal "test1\ntest2", strip_html(body, options)
  end

  def test_html_tags_with_strip_setting
    body = "<b>test1</b><br>test2"
    options = {:strip_html_tags => '1'}

    assert_equal "test1\ntest2", strip_html(body, options)
  end

  def test_html_tags_without_strip_setting
    body = "<b>test1</b><br>test2"
    options = {:strip_html_tags => '0'}

    assert_equal "<b>test1</b><br>test2", strip_html(body, options)
  end
end