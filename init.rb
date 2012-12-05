require 'redmine'

# Patches to the Redmine core.
require 'dispatcher'
require 'xls_export'
require 'issues_controller_xls_patch'

Dispatcher.to_prepare :redmine_xls_export do
	
	Mime::Type.register('application/vnd.ms-excel', :xls, %w(application/vnd.ms-excel)) unless defined? Mime::XLS

	unless IssuesController.included_modules.include? IssuesControllerXLSPatch
	  IssuesController.send(:include, IssuesControllerXLSPatch)
	end

end

unless Redmine::Plugin.registered_plugins.keys.include?(:redmine_xls_export)
  Redmine::Plugin.register :redmine_xls_export do
    name 'Issues XLS export'
    author 'Vitaly Klimov'
    author_url 'mailto:vvk@snowball.ru'
    description 'This plugin requires spreadsheet gem. This build compatible with version of Redmine 1.0.1 or higher'
    version '0.1.3'

    settings(:partial => 'settings/xls_export_settings',
             :default => {
               'relations' => '1',
               'watchers' => '1',
               'description' => '1',
               'time' => '0',
               'attachments' => '0',
               'query_columns_only' => '0',
               'group' => '0',
               'generate_name' => '1',
               'issues_limit' => '0',
               'export_name' => 'issues_export'
             })

    requires_redmine :version_or_higher => '1.0.1'

  end

  require 'xls_export_hooks'

end
