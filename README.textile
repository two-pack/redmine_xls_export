h2. IMPORTANT INFORMATION

Original plugin created by Vitaly Klimov. Thanks his great work!
See following urls.
http://www.redmine.org/plugins/redmine_xls_export
http://www.redmine.org/boards/3/topics/11986

And some features and translations, which are almost from above forum, are added on following github:
https://github.com/two-pack/redmine_xls_export
* 'official' branch has original source.
* 'features' branch has something added to original.


h2. Project Health

!https://travis-ci.org/two-pack/redmine_xls_export.svg?branch=features!:https://travis-ci.org/two-pack/redmine_xls_export


h2. XLS export plugin

With the help of this plugin you can export issues list with all information to XLS file. Also it is possible to export issues with attachments as a ZIP archive.

h3. Requirements

* Redmine version 1.3.0 or higher.
* "Plugin views with revisions":http://www.redmine.org/plugins/redmine_plugin_views_revisions


h3. Installation and Setup

# Run bundler ('bundle install') or with option ('bundle install --without export_attachments') if you want to use export attachments feature
 *NOTE: Remove specified version for 'rubyzip' and 'zip-zip' in Gemfile if you use Redmine 2.3.x or older before ‘bundle install’.*
# Follow the Redmine plugin installation steps at: http://www.redmine.org/wiki/redmine/Plugins
# Login and configure the plugin (Administration > Plugins > Configure)

If you use Redmine 2.2.x or older, Do following steps.

# Install plugin "Plugin views with revisions":http://www.redmine.org/plugins/redmine_plugin_views_revisions if you do not have it installed
# Run rake task
 *rake redmine:plugins:process_version_change RAILS_ENV=production*


h3. Features

* Export active or all columns
* Export issue descriptions
* Export journal entries - both inline or as separate file per each issue
* Export status histories
* Export relations information
* Export spent time data
* List attachments information
* Export attachments
* Export watchers
* Split information by sheets based on grouping criteria
* Correct formatting and width of worksheet cells

h3. Details

Plugin adds following links with 'XLS export:' prefix at the bottom of the page under 'Also available in' bar:

* *Quick*
 One click export to XLS using default export settings from plugin configuration screen
* *Detailed*
 Brings up dialog where user can choose export options before export

h3. History

0.2.1.t8 (on github)
* Supported Redmine 3.0.x and 2.6.x.
* Added option to strip HTML tags.
* Added Vietnamese localization.
* Improved Czech localization.
* Fixed a bug.

0.2.1.t7 (on github)
* Added CI environment.
* Fixed to use local timezone.
* Added date format for "Closed".
* Some bug fixes.

0.2.1.t6 (on github)
* Supported Redmine 2.5.x.
* Ability to export status histories.
* Added default templates and stylesheet.
* Added hyperlink on issue ID.
* Changed color of columns header.
* Fixed some bugs.
* Added Serbian localization.
* Improved some localizations.
* Added smoke testing.

0.2.1.t5 (on github)
* Fixed to export invisible private note.
* Added Turkish localization.

0.2.1.t4 (on github)
* Re-formatted a settings view of date format. 
* Fixed Czech localization.
* Fixed description column duplicated.

0.2.1.t3 (on github)

* Fixed invalid export result when issue has multiple values of custom fields.
* Fixed a source in the Gemfile.
* Added Bulgarian translations of several labels.

0.2.1.t2 (on github)

* Supported Redmine 2.3.0.
* Added and fixes some translations for German.
* Fixed invalid ruby zip message on admin plugin settings when open this page with first action.
* Fixed that Internal Server Error is occurred with QUICK export when date formats are empty.

0.2.1.t1 (additional features & translations on github)

* Added Gemfile for bundle setup.
* Ability to set cell format for date & time.
* Some translations added from above forum.
** Korean
** Polish
** Portuguese(Brazil)
** Traditional chinese

0.2.1

* Journal export compatibility fixes
* Japanese & China translations updated

0.2.0

* Plugin depends on "Plugin views with revisions":http://www.redmine.org/plugins/redmine_plugin_views_revisions for further Redmine compatibility
* Rails 3 (Redmine 2.x.x) compatibility added
* Controller completely rewritten - no more IssuesController monkey-patch
* Journal entries could be exported as well
* Ability to export journal entries in separate files, one per each issue
* Ability to export attachments in ZIP file
* Ability to set start offset for export
