require 'xlse_asset_helpers'

class XLSExportHook < Redmine::Hook::ViewListener
  def view_issues_index_bottom(context={})
    if context[:query].valid? && !context[:issues].empty?
      ret_str =''
      ret_str << stylesheet_link_tag("xls_export.css", :plugin => XLSE_AssetHelpers::PLUGIN_NAME, :media => "screen")
      ret_str << '<p class="other-formats">' << l(:label_plugin_xlse_export_format)
      ret_str << content_tag('span', link_to(l(:label_plugin_xlse_export_format_quick),
                                             hook_url_for({ :controller => 'xls_export', :action => 'export_current', :project_id => context[:project] }),
                                             { :class => 'xls', :rel => 'nofollow', :title => l(:label_plugin_xlse_export_format_quick_tooltip) }))
      ret_str << content_tag('span', link_to(l(:label_plugin_xlse_export_format_detailed),
                                             hook_url_for({ :controller => 'xls_export', :action => 'index', :project_id => context[:project] }),
                                             { :class => 'xlse', :title => l(:label_plugin_xlse_export_format_detailed_tooltip) }))
      ret_str << '</p>'

      return ret_str.html_safe
    end
  end

  def suburi(url)
    baseurl = Redmine::Utils.relative_url_root
    if not url.match(/^#{baseurl}/)
      url = baseurl + url
    end
    return url
  end

  def hook_url_for(url)
    if Rails::VERSION::MAJOR >= 3 && Redmine::Utils::relative_url_root != ''
      suburi("#{url_for(url)}")
    else
      url
    end
  end
end
