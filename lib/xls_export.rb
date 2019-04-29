require_dependency 'spreadsheet'
require 'uri'
require 'rubygems'
require 'nokogiri'

module Redmine
  module Export
    module XLS
      module StripHTML
        def strip_html(str, options)
          if options[:strip_html_tags] == '1'
            document = Nokogiri::HTML.parse(str)
            document.css("br").each { |node| node.replace("\n") }
            document.text
          else
            str
          end
        end
      end
    end
  end
end

# taken from 'query'
class XLS_QueryColumn
  attr_accessor :name, :sortable, :groupable, :default_order
  include Redmine::I18n

  def initialize(name, options={})
    self.name = name
    self.sortable = options[:sortable]
    self.groupable = options[:groupable] || false
    if groupable == true
      self.groupable = name.to_s
    end
    self.default_order = options[:default_order]
    @caption_key = options[:caption] || "field_#{name}"
  end

  def caption
    l(@caption_key)
  end

  # Returns true if the column is sortable, otherwise false
  def sortable?
    !@sortable.nil?
  end

  def sortable
    @sortable.is_a?(Proc) ? @sortable.call : @sortable
  end

  def value(issue)
    issue.send name
  end

  def css_classes
    name
  end

  # for redmine_category_tree plugin
  def h(s)
    s
  end

  # for redmine_category_tree plugin
  def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true)
    if options[:class] == "parent"
      content_or_options_with_block + " > "
    else
      content_or_options_with_block
    end
  end
end

class XLS_SpentTimeQueryColumn < XLS_QueryColumn
  def caption
    l(:label_spent_time)
  end

  def value(issue)
    issue.spent_hours
  end
end

class XLS_AttachmentQueryColumn < XLS_QueryColumn
  def caption
    l(:label_plugin_xlse_field_attachment)
  end

  def value(issue)
    issue.attachments
  end
end

class XLS_JournalQueryColumn < XLS_QueryColumn
  include CustomFieldsHelper
  include IssuesHelper
  include Redmine::Export::XLS::StripHTML

  def caption
    l(:label_plugin_xlse_field_journal)
  end

  def value(issue, options)
    hist_str = ''
    issue_updates = issue.journals.includes(:user, :details).order("#{Journal.table_name}.created_on ASC").to_a
    issue_updates.each do |journal|
      if !journal.private_notes? or User.current.allowed_to?(:view_private_notes, journal.project)
        hist_str << "#{format_time(journal.created_on)} - #{journal.user.name}\n"
        journal.details.each do |detail|
          hist_str <<  " - #{show_detail(detail, true)}"
          hist_str << "\n" unless detail == journal.details.last
        end
        if journal.notes?
            hist_str << "\n" unless journal.details.empty?
            hist_str << journal.notes.to_s
        end
        hist_str << "\n" unless journal == issue_updates.last
      end
    end
    strip_html(hist_str, options)
  end
end


module Redmine
  module Export
    module XLS
      include Redmine::Export::XLS::StripHTML
      unloadable

      def show_value_for_xls(value)
        if CustomFieldsHelper.instance_method(:show_value).arity == 1
          show_value(value)
        else
          show_value(value, false)
        end
      end

      def add_date_format(date_formats, tag, format, default)
        date_formats[tag] = (format == nil) ? default : format
      end

      def init_date_formats(options)
        date_formats = {}
        add_date_format(date_formats, :created_on, options[:created_format], l("default_created_format"))
        add_date_format(date_formats, :updated_on, options[:updated_format], l("default_updated_format"))
        add_date_format(date_formats, :start_date, options[:start_date_format],l("default_start_date_format"))
        add_date_format(date_formats, :due_date, options[:due_date_format], l("default_due_date_format"))
        add_date_format(date_formats, :closed_on, options[:closed_date_format], l("default_closed_date_format"))

        date_formats
      end

      def has_in_query?(query, name)
        query.available_columns.each do |c|
          return true if c.name == name
        end
        return false
      end

      def has_id?(query)
        has_in_query?(query, :id)
      end

      def has_description?(query)
        has_in_query?(query, :description)
      end

      def has_spent_time?(query)
        has_in_query?(query, :description)
      end

      def use_export_description_setting?(query, options)
        if has_description?(query) == false && options[:description] == '1'
          return true
        end
        return false
      end

      def use_export_spent_time?(query, options)
        if has_spent_time?(query) == false && options[:time] == '1'
          return true
        end
        return false
      end

      def init_row(row, query, first)
        if has_id?(query)
          row.replace []
        else
          row.replace [first]
        end
      end

      def insert_issue_id(row, issue)
        issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
        row << Spreadsheet::Link.new(URI.escape(issue_url), issue.id.to_s)
        format_link = Spreadsheet::Format.new :color => :blue, :underline => :single
        row.set_format(row.size - 1, format_link)
      end

      def create_issue_columns(project, query, options)
        issue_columns = []

        (options[:query_columns_only] == '1' ? query.columns : query.available_columns).each do |c|
          case c.name
            when :relations
              issue_columns << c if options[:relations] == '1'
            when :estimated_hours
              issue_columns << XLS_SpentTimeQueryColumn.new(:spent_time) if use_export_spent_time?(query, options)
              issue_columns << c if column_exists_for_project?(c, project)
            else
              issue_columns << c if column_exists_for_project?(c, project)
          end
        end

        issue_columns << QueryColumn.new(:watcher) if options[:watchers] == '1'
        issue_columns << XLS_AttachmentQueryColumn.new(:attachments) if options[:attachments] == '1'
        issue_columns << XLS_JournalQueryColumn.new(:journal) if options[:journal] == '1'
        issue_columns << QueryColumn.new(:description) if use_export_description_setting?(query, options)
        issue_columns
      end

      def localtime(datetime)
        if datetime
          User.current.time_zone ? datetime.in_time_zone(User.current.time_zone) : datetime.localtime
        end
      end

# options are
# :relations - export relations
# :watchers - export watchers
# :time - export time spent
# :journal - export journal entries
# :journal_worksheets - export journal entries to worksheets
# :description - export descriptions
# :attachments - export attachments info
# :query_columns_only - export only columns from actual query
# :group - group by query grouping
      def issues_to_xls2(issues, project, query, options = {})

        Spreadsheet.client_encoding = 'UTF-8'

        date_formats = init_date_formats(options);

        group_by_query=query.grouped? ? options[:group] : false
        book = Spreadsheet::Workbook.new
        issue_columns = create_issue_columns(project, query, options)

        sheet1 = nil
        group = false
        columns_width = []
        idx = 0
# xls rows
        issues.each do |issue|
          if group_by_query == '1'
            new_group=query_get_group_column_name(issue,query)
            if new_group != group
              group = new_group
              update_sheet_formatting(sheet1,columns_width) if sheet1
              sheet1 = book.create_worksheet(:name => (group.blank? ? l(:label_none) : pretty_xls_tab_name(group.to_s)))
              columns_width=init_header_columns(query, sheet1,issue_columns,date_formats)
              idx = 0
            end
          else
            if sheet1 == nil
              sheet1 = book.create_worksheet(:name => l(:label_issue_plural))
              columns_width=init_header_columns(query, sheet1,issue_columns,date_formats)
            end
          end

          row = sheet1.row(idx+1)
          init_row(row, query, issue.id)

          lf_pos = get_value_width(issue.id)
          columns_width[0] = lf_pos unless columns_width[0] >= lf_pos

          last_prj = project

          issue_columns.each_with_index do |c, j|
            v = if c.is_a?(QueryCustomFieldColumn)
              case c.custom_field.field_format
                when "int"
                  begin
                    Integer(issue.custom_value_for(c.custom_field).to_s)
                  rescue
                    show_value_for_xls(issue.custom_value_for(c.custom_field))
                  end
                when "float"
                  begin
                    Float(issue.custom_value_for(c.custom_field).to_s)
                  rescue
                    show_value_for_xls(issue.custom_value_for(c.custom_field))
                  end
                when "date"
                  begin
                    Date.parse(issue.custom_value_for(c.custom_field).to_s)
                  rescue
                    show_value_for_xls(issue.custom_value_for(c.custom_field))
                  end
                else
                  value = issue.custom_field_values.detect {|v| v.custom_field == c.custom_field}
                  show_value_for_xls(value) unless value.nil?
              end
            else
              case c.name
                when :done_ratio
                  (Float(issue.send(c.name)))/100
                when :description
                  descr_str = ''
                  strip_html(issue.description, options).to_s.each_char do |c_a|
                    if c_a != "\r"
                      descr_str << c_a
                    end
                  end
                  descr_str
                when :relations
                  rel_str = ''
                  relations = issue.relations.select {|r| r.other_issue(issue).visible?}
                  relations.each do |relation|
                    rel_str << l(relation.label_for(issue)) << ' '
                    rel_str << relation.other_issue(issue).tracker.to_s << ' #'
                    rel_str << relation.other_issue(issue).id.to_s
                    rel_str << "\n" unless relation == relations.last
                  end unless relations.empty?
                  rel_str
                when :watcher
                  rel_str=''
                  if(User.current.allowed_to?(:view_issue_watchers, last_prj) && !issue.watcher_users.empty?)
                    rel_str = issue.watcher_users.collect(&:to_s).join("\n")
                    #issue.watcher_users.each do |user|
                    #  rel_str << user.to_s
                    #  rel_str << "\n" unless user == issue.watcher_users.last
                    #end
                  end
                  rel_str
                when :spent_time
                  if User.current.allowed_to?(:view_time_entries, last_prj)
                    c.value(issue)
                  else
                    ''
                  end
                when :attachments
                  c.value(issue).to_a.map {|a| a.filename}.join("\n")
                when :journal
                  c.value(issue, options)
                when :project
                  last_prj = issue.send(c.name)
                  last_prj
                when :created_on, :updated_on, :closed_on
                  datetime = issue.respond_to?(c.name) ? issue.send(c.name) : c.value(issue)
                  localtime(datetime)
                when :"parent.subject"
                  issue.parent.nil? ? "" : issue.parent.subject
              else
                issue.respond_to?(c.name) ? issue.send(c.name) : c.value(issue)
              end
            end

            value = %w(Time Date Fixnum Float Integer String).include?(v.class.name) ? v : v.to_s

            lf_pos = get_value_width(value)
            index = has_id?(query) ? j : j + 1
            columns_width[index] = lf_pos unless columns_width[index] >= lf_pos
            if c.name == :id
              insert_issue_id(row, issue)
            else
              row << value
            end
          end

          idx = idx + 1

          if options[:journal_worksheets]
              journal_details_to_xls(issue, options, book)
          end
          
        end

        if sheet1
          update_sheet_formatting(sheet1,columns_width)
        else
          sheet1 = book.create_worksheet(:name => 'Issues')
          sheet1.row(0).replace [l(:label_no_data)]
        end

        xls_stream = StringIO.new('')
        book.write(xls_stream)

        return xls_stream.string
      end

      def journal_details_to_xls(issue, options, book_to_add = nil)
        issue_updates = issue.journals.includes(:user, :details).order("#{Journal.table_name}.created_on ASC").to_a
        return nil if issue_updates.size == 0

        Spreadsheet.client_encoding = 'UTF-8'
        book = book_to_add ? book_to_add : Spreadsheet::Workbook.new
        sheet1 = book.create_worksheet(:name => "%05i - Journal" % [issue.id])

        columns_width = []
        sheet1.row(0).replace []
        ['#',l(:field_updated_on),l(:field_user),l(:label_details),l(:field_notes)].each do |c|
          sheet1.row(0) << c
          columns_width << (get_value_width(c)*1.1)
        end
        sheet1.column(0).default_format = Spreadsheet::Format.new(:number_format => "0")

        idx=0
        issue_updates.each do |journal|
          if !journal.private_notes? or User.current.allowed_to?(:view_private_notes, journal.project)
            row = sheet1.row(idx+1)
            row.replace []

            details=''
            journal.details.each do |detail|
              details <<  "#{show_detail(detail, true)}"
              details << "\n" unless detail == journal.details.last
            end
            details = strip_html(details, options)
            notes = strip_html(journal.notes? ? journal.notes.to_s : '', options)

            [idx+1,localtime(journal.created_on),journal.user.name,details,notes].each_with_index do |e,e_idx|
              lf_pos = get_value_width(e)
              columns_width[e_idx] = lf_pos unless columns_width[e_idx] >= lf_pos
              row << e
            end

            idx=idx+1
          end
        end

        update_sheet_formatting(sheet1,columns_width)

        if book_to_add.nil?
            xls_stream = StringIO.new('')
            book.write(xls_stream)
            xls_stream.string
        end
      end

      def column_exists_for_project?(column, project)
        return true unless (column.is_a?(QueryCustomFieldColumn) && project != nil)

        project.trackers.each do |t|
          t.custom_fields.each do |c|
            if c.id == column.custom_field.id
              return true
            end
          end
        end

        return false
      end

      def init_header_columns(query, sheet1,columns,date_formats)

        columns_width = has_id?(query) ? [] : [1]
        init_row(sheet1.row(0), query, "#")

        columns.each do |c|
          sheet1.row(0) << c.caption
          columns_width << (get_value_width(c.caption)*1.1)
        end
        # id
        sheet1.column(0).default_format = Spreadsheet::Format.new(:number_format => "0")

        opt = Hash.new
        columns.each_with_index do |c, idx|
          width = 0
          opt.clear

          if c.is_a?(QueryCustomFieldColumn)
            case c.custom_field.field_format
              when "int"
                opt[:number_format] = "0"
              when "float"
                opt[:number_format] = "0.00"
            end
          else
            case c.name
              when :done_ratio
                opt[:number_format] = '0%'
              when :estimated_hours, :spent_time
                opt[:number_format] = "0.0"
              when :created_on, :updated_on, :start_date, :due_date, :closed_on
                opt[:number_format] = date_formats[c.name]
            end
          end

          sheet1.column(idx).default_format = Spreadsheet::Format.new(opt) unless opt.empty?
          columns_width[idx] = width unless columns_width[idx] >= width
        end

        return columns_width
      end

      def update_sheet_formatting(sheet1,columns_width)

        sheet1.row(0).count.times do |idx|

            do_wrap = columns_width[idx] > 60 ? 1 : 0
            sheet1.column(idx).width = columns_width[idx] > 60 ? 60 : columns_width[idx]

            if do_wrap
              fmt = Marshal::load(Marshal.dump(sheet1.column(idx).default_format))
              fmt.text_wrap = true
              sheet1.column(idx).default_format = fmt
            end

            fmt = Marshal::load(Marshal.dump(sheet1.row(0).format(idx)))
            fmt.font.bold=true
            fmt.pattern=1
            fmt.pattern_bg_color=:gray
            fmt.pattern_fg_color=:gray
            fmt.font.color = :white
            sheet1.row(0).set_format(idx,fmt)
        end

      end

      def get_value_width(value)

        if %w(Time Date).include?(value.class.name)
          return 18 unless value.to_s.length < 18
        end

        tot_w = Array.new
        tot_w << Float(0)
        idx=0
        value.to_s.each_char do |c|
          case c
            when '1', '.', ';', ':', ',', ' ', 'i', 'I', 'j', 'J', '(', ')', '[', ']', '!', '-', 't', 'l'
              tot_w[idx] += 0.6
            when 'W', 'M', 'D'
              tot_w[idx] += 1.2
            when "\n"
              idx = idx + 1
              tot_w << Float(0)
          else
            tot_w[idx] += 1.05
          end
        end

        wdth=0
        tot_w.each do |w|
          wdth = w unless w<wdth
        end

        return wdth+1.5
      end

      def query_get_group_column_name(issue,query)
        gc=query.group_by_column

        return issue.send(query.group_by) unless gc.is_a?(QueryCustomFieldColumn)

        cf=issue.custom_values.detect do |c|
          true if c.custom_field_id == gc.custom_field.id
        end

        return cf==nil ? l(:label_none) : cf.value
      end

      def pretty_xls_tab_name(org_name)
        return org_name.gsub(/[\\\/\[\]\?\*:"']/, '_')
      end


      def init_status_histories_book()
        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet(:name => "Status histories")
        return book, sheet
      end

      def add_columns_header_for_status_histories(sheet)
        columns_width = []
        sheet.row(0).replace []
        ['#', l(:field_project), l(:plugin_xlse_field_issue_created_on),  l(:field_updated_on),
         l(:plugin_xlse_field_status_from), l(:plugin_xlse_field_status_to)].each do |c|
          sheet.row(0) << c
          columns_width << (get_value_width(c) * 1.1)
        end

        return columns_width
      end

      def set_columns_default_format(sheet, options)
        date_formats = init_date_formats(options);

        number_formats = ['0', nil, date_formats[:created_on], date_formats[:updated_on], nil, nil]
        format = Hash.new
        number_formats.each_with_index do |number_format, idx|
          format.clear
          format[:number_format] = number_format unless number_format.nil?
          sheet.column(idx).default_format = Spreadsheet::Format.new(format) unless format.empty?
        end
      end

      def hash_issue_statuses
        array = IssueStatus.all
        hash = Hash.new
        array.each do |item|
          hash.store(item.id.to_s, item.name)
        end
        return hash
      end

      def get_issue_status(id, issue_statuses)
        issue_statuses.has_key?(id) ? issue_statuses[id] : id
      end

      def extract_status_histories(sheet, columns_width, issues)
        issue_statuses = hash_issue_statuses()

        idx = 0
        issues.each do |issue|
          issue_updates = issue.journals.includes(:user, :details).order("#{Journal.table_name}.created_on ASC").to_a
          next if issue_updates.size == 0

          issue_updates.each do |journal|
            journal.details.each do |detail|
              if detail.prop_key == "status_id"
                row = sheet.row(idx+1)
                row.replace []

                project = issue.respond_to?(:project) ? issue.send(:project).name : issue.project_id.to_s
                status_from = get_issue_status(detail.old_value, issue_statuses)
                status_to = get_issue_status(detail.value, issue_statuses)
                [issue.id, project, localtime(issue.created_on), localtime(journal.created_on), status_from, status_to].each_with_index do |e, e_idx|
                  lf_pos = get_value_width(e)
                  columns_width[e_idx] = lf_pos unless columns_width[e_idx] >= lf_pos
                  row << e
                end
                idx = idx+1
              end
            end
          end
        end

        return columns_width
      end

      def status_histories_to_xls(issues, options = {})
        book, sheet = init_status_histories_book()
        columns_width = add_columns_header_for_status_histories(sheet)
        set_columns_default_format(sheet, options)
        columns_width = extract_status_histories(sheet, columns_width, issues)

        update_sheet_formatting(sheet, columns_width)

        xls_stream = StringIO.new('')
        book.write(xls_stream)
        xls_stream.string
      end

    end
  end
end
