if Rails::VERSION::MAJOR >= 3
  RedmineApp::Application.routes.draw do
    match 'issues_xls_export', :to => 'xls_export#index', :via => [:get, :post]
    get 'issues_xls_export_current', :to => 'xls_export#export_current'
    match 'projects/:project_id/issues_xls_export', :to => 'xls_export#index', :via => [:get, :post]
    get 'projects/:project_id/issues_xls_export_current', :to => 'xls_export#export_current'
  end
else
  ActionController::Routing::Routes.draw do |map|
    map.with_options :controller => 'xls_export' do |issues_routes|
      issues_routes.with_options :conditions => {:method => :get} do |issues_views|
        issues_views.connect 'issues_xls_export', :action => 'index'
        issues_views.connect 'issues_xls_export_current', :action => 'export_current'
        issues_views.connect 'projects/:project_id/issues_xls_export', :action => 'index'
        issues_views.connect 'projects/:project_id/issues_xls_export_current', :action => 'export_current'
      end
    end
    map.with_options :controller => 'xls_export' do |issues_routes|
      issues_routes.with_options :conditions => {:method => :post} do |issues_views|
        issues_views.connect 'issues_xls_export', :action => 'index'
        issues_views.connect 'issues_xls_export_current', :action => 'export_current'
        issues_views.connect 'projects/:project_id/issues_xls_export', :action => 'index'
        issues_views.connect 'projects/:project_id/issues_xls_export_current', :action => 'export_current'
      end
    end
  end
end
