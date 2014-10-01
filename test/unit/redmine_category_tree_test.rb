require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

require File.expand_path(File.dirname(__FILE__) + '/../../lib/xls_export')

class RedmineCategoryTreeTest < ActiveSupport::TestCase

  def setup
    @sut = XLS_QueryColumn.new(:test)
  end

  def teardown
    # Do nothing
  end

  def test_not_to_escape
    assert_equal "<&?@>", @sut.h("<&?@>")
  end

  def test_parent_of_category_is_added_gt_character
    assert_equal "content > ", @sut.content_tag(nil, "content", :class => "parent")
  end

  def test_issue_category_is_not_added_gt_character
    assert_equal "content", @sut.content_tag(nil, "content", :class => "issue_category")
  end

  def test_issue_category_tree_is_not_added_gt_character
    assert_equal "content", @sut.content_tag(nil, "content", :class => "issue_category_tree")
  end

end