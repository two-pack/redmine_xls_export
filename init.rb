require 'redmine'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
require 'xlse_asset_helpers'
begin
  require 'zip/zip'
rescue LoadError
  ActionController::Base::logger.info 'XLS export controller: rubyzip gem not available'
end

unless Redmine::Plugin.registered_plugins.keys.include?(XLSE_AssetHelpers::PLUGIN_NAME)
  Redmine::Plugin.register XLSE_AssetHelpers::PLUGIN_NAME do
    name 'Issues XLS export'
    author 'Vitaly Klimov'
    author_url 'mailto:vitaly.klimov@snowbirdgames.com'
    description 'Export issues to XLS files including journals, descriptions, etc. This plugin requires spreadsheet gem.'
    version '0.2.1.t8'

    settings(:partial => 'settings/xls_export_settings',
             :default => {
               'relations' => '1',
               'watchers' => '1',
               'description' => '1',
               'journal' => '0',
               'time' => '0',
               'attachments' => '0',
               'query_columns_only' => '0',
               'group' => '0',
               'generate_name' => '1',
               'strip_html_tags' => '0',
               'export_attached' => '0',
               'separate_journals' => '0',
               'export_status_histories' => '0',
               'issues_limit' => '0',
               'export_name' => 'issues_export',
               'created_format' => "dd.mm.yyyy hh:mm:ss",
               'updated_format' => "dd.mm.yyyy hh:mm:ss",
               'start_date_format' => "dd.mm.yyyy",
               'due_date_format' => "dd.mm.yyyy",
               'closed_date_format' => "dd.mm.yyyy hh:mm:ss"
             })

    requires_redmine :version_or_higher => '1.3.0'
  end

  require 'xls_export_hooks'
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    Mime::Type.register('application/vnd.ms-excel', :xls, %w(application/vnd.ms-excel)) unless defined?(Mime::XLS)
    Mime::Type.register('application/zip', :zip, %w(application/zip)) unless defined?(Mime::ZIP)
  end
else
  Dispatcher.to_prepare XLSE_AssetHelpers::PLUGIN_NAME do
    Mime::Type.register('application/vnd.ms-excel', :xls, %w(application/vnd.ms-excel)) unless defined?(Mime::XLS)
    Mime::Type.register('application/zip', :zip, %w(application/zip)) unless defined?(Mime::ZIP)
  end
end
