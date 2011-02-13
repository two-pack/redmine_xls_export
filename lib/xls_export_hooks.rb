
class XLSExportHook < Redmine::Hook::ViewListener
  def view_issues_index_bottom(context={})
    if context[:query].valid? && !context[:issues].empty?
      ret_str =''
      ret_str << stylesheet_link_tag("xls_export.css", :plugin => "redmine_xls_export", :media => "screen")
      ret_str << '<p class="other-formats">' << l(:label_plugin_xlse_export_format)
      ret_str << content_tag('span', link_to(l(:label_plugin_xlse_export_format_quick),
                                            { :controller => 'issues', :action => 'index', :project_id => context[:project], :format => 'xls' },
                                            { :class => 'xls', :rel => 'nofollow', :title => l(:label_plugin_xlse_export_format_quick_tooltip) }))
      ret_str << content_tag('span', link_to(l(:label_plugin_xlse_export_format_detailed),
                                            { :controller => 'issues', :action => 'xls_export_action', :project_id => context[:project] },
                                            { :class => 'xlse', :title => l(:label_plugin_xlse_export_format_detailed_tooltip) }))
      ret_str << '</p>'

      return ret_str
    end
  end
end
