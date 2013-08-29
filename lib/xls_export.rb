require_dependency 'spreadsheet'

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
    return '' unless issue.attachments.any?

    str = ''
    issue.attachments.each do |a|
      str << a.filename
      str << " - #{a.description}" unless a.description.blank?
      str << "\n" unless a==issue.attachments.last
    end
    str
  end
end

class XLS_JournalQueryColumn < XLS_QueryColumn
  include CustomFieldsHelper
  include IssuesHelper

  def caption
    l(:label_plugin_xlse_field_journal)
  end

  def value(issue)
    hist_str = ''
    issue_updates = issue.journals.all(:include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    issue_updates.each do |journal|
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
    hist_str
  end
end


module Redmine
  module Export
    module XLS
      unloadable

      def add_date_format(date_formats, tag, format, default)
        date_formats[tag] = (format == nil) ? default : format
      end

      def init_date_formats(options)
        date_formats = {}
        add_date_format(date_formats, :created_on, options[:created_format], l("default_created_format"))
        add_date_format(date_formats, :updated_on, options[:updated_format], l("default_updated_format"))
        add_date_format(date_formats, :start_date, options[:start_date_format],l("default_start_date_format"))
        add_date_format(date_formats, :due_date, options[:due_date_format], l("default_due_date_format"))

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

      def create_issue_columns(project, query, options)
        issue_columns = []

        (options[:query_columns_only] == '1' ? query.columns : query.available_columns).each do |c|
          case c.name
            when :formatted_relations
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

# options are
# :relations - export relations
# :watchers - export watchers
# :time - export time spent
# :journal - export journal entries
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
              value = issue.custom_field_values.detect {|v| v.custom_field == c.custom_field}
              show_value(value) unless value.nil?
            else
              case c.name
                when :done_ratio
                  (Float(issue.send(c.name)))/100
                when :description
                  descr_str = ''
                  issue.description.to_s.each_char do |c_a|
                    if c_a != "\r"
                      descr_str << c_a
                    end
                  end
                  descr_str
                when :formatted_relations
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
                  c.value(issue)
                when :journal
                  c.value(issue)
                when :project
                  last_prj = issue.send(c.name)
                  last_prj
              else
                issue.respond_to?(c.name) ? issue.send(c.name) : c.value(issue)
              end
            end

            value = %w(Time Date Fixnum Float Integer String).include?(v.class.name) ? v : v.to_s

            lf_pos = get_value_width(value)
            index = has_id?(query) ? j : j + 1
            columns_width[index] = lf_pos unless columns_width[index] >= lf_pos
            row << value
          end

          idx = idx + 1

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

      def journal_details_to_xls(issue)
        issue_updates = issue.journals.all(:include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
        return nil if issue_updates.size == 0

        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet::Workbook.new
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
          row = sheet1.row(idx+1)
          row.replace []

          details=''
          journal.details.each do |detail|
            details <<  "#{show_detail(detail, true)}"
            details << "\n" unless detail == journal.details.last
          end
          notes=(journal.notes? ? journal.notes.to_s : '')

          [idx+1,journal.created_on,journal.user.name,details,notes].each_with_index do |e,e_idx|
            lf_pos = get_value_width(e)
            columns_width[e_idx] = lf_pos unless columns_width[e_idx] >= lf_pos
            row << e
          end

          idx=idx+1
        end

        update_sheet_formatting(sheet1,columns_width)

        xls_stream = StringIO.new('')
        book.write(xls_stream)
        xls_stream.string
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
              when :created_on, :updated_on, :start_date, :due_date
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

    end
  end
end
