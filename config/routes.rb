ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'issues' do |issues_routes|
    issues_routes.with_options :conditions => {:method => :get} do |issues_views|
      issues_views.connect 'issues/xls_export_action', :action => 'xls_export_action'
      issues_views.connect 'projects/:project_id/issues/xls_export_action', :action => 'xls_export_action'
    end
  end
end