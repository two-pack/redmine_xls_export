
require 'query' 
require 'spreadsheet'

class SpentTimeQueryColumn < QueryColumn  
  def caption
    l(:label_spent_time)
  end
  
  def value(issue)
    issue.spent_hours
  end
end

class AttachmentQueryColumn < QueryColumn  
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
  	return str
  end
end

module Redmine
	module Export
		module XLS
		unloadable

		def issue_list(issues, &block)
    			ancestors = []
    			issues.each do |issue|
      			while (ancestors.any? && !issue.is_descendant_of?(ancestors.last))
        			ancestors.pop
      			end
      			yield issue, ancestors.size
      			ancestors << issue unless issue.leaf?
   			end
  		end
		
# options are
# :relations - export relations
# :watchers - export watchers
# :time - export time spent
# :description - export descriptions
# :history - export history
# :attachments - export attachments info
# :query_columns_only - export only columns from actual query
# :group - group by query grouping  
		def issues_to_xls2(issues, project, query, options = {}, sort_parent = false)
	
			Spreadsheet.client_encoding = 'UTF-8'
			options[:date_format] ||= 'dd.mm.yyyy'
			options.default=false
			show_relations = options[:relations]
			show_watchers = options[:watchers] 
			show_time = options[:time]
			show_descr = options[:description]
      show_hist = options[:history]
			query_columns_only = options[:query_columns_only]
			show_attachment = options[:attachments]
      date_format = options[:date_format]
			group_by_query = query.grouped? ? options[:group] : false
	
			book = Spreadsheet::Workbook.new
	    
			issue_columns = []
	    
	    (query_columns_only == '1' ? query.columns : query.available_columns).each do |c|
	    	if c.name == :formatted_relations
	    		issue_columns << c unless show_relations != '1'
				else    		
		    	issue_columns << c unless !column_exists_for_project?(c,project)
	    	end
	    	if c.name == :estimated_hours and show_time == '1'
	    		issue_columns << SpentTimeQueryColumn.new(:spent_time)
	    	end
	    end
	    
	    if show_watchers == '1'
	    	issue_columns << QueryColumn.new(:watcher)
    	end
    	
    	if show_attachment == '1'
    		issue_columns << AttachmentQueryColumn.new(:attachments)
    	end
    	
    	if show_descr == '1'
	    	issue_columns << QueryColumn.new(:description)
	   end
    
      if show_hist == '1'
        issue_columns << QueryColumn.new(:history)
      end
	    
	    sheet1 = nil
			group = false
			columns_width = []
			idx = 0
# xls rows			
			issue_list(issues) do |issue, level|

				if group_by_query == '1'
					new_group=query_get_group_column_name(issue,query)
					if new_group != group
						group = new_group
						update_sheet_formatting(sheet1,columns_width) if sheet1
						sheet1 = book.create_worksheet(:name => (group.blank? ? l(:label_none) : pretty_xls_tab_name(group.to_s)))
						columns_width=init_header_columns(sheet1,issue_columns)
						idx = 0
					end
				else
					if sheet1 == nil
						sheet1 = book.create_worksheet(:name => l(:label_issue_plural))
						columns_width=init_header_columns(sheet1,issue_columns)
					end
				end
			
				row = sheet1.row(idx+1)
				
				row.replace [issue.id]
				
				
				lf_pos = get_value_width(issue.id)
				columns_width[0] = lf_pos unless columns_width[0] >= lf_pos
				
				last_prj = project

				if level > 0
					s = s.to_s.rjust(level*3) 					
					issue.subject = s + issue.subject
				end
				
        if issue.children? and sort_parent then
          fmt = Spreadsheet::Format.new :weight => :bold
        else
          fmt = Spreadsheet::Format.new
        end

				issue_columns.each_with_index do |c, j|
					v = if c.is_a?(QueryCustomFieldColumn)
						case c.custom_field.field_format
							when "int"
								begin
									fmt.number_format = "0"
									Integer(issue.custom_value_for(c.custom_field).to_s)
								rescue
									show_value(issue.custom_value_for(c.custom_field))
								end
							when "float"
								begin
									fmt.number_format = "0.00"
									Float(issue.custom_value_for(c.custom_field).to_s)
								rescue
									show_value(issue.custom_value_for(c.custom_field))
								end
							when "date"
								begin
									fmt.number_format = date_format
									Date.parse(issue.custom_value_for(c.custom_field).to_s)
								rescue
									show_value(issue.custom_value_for(c.custom_field))
								end
						else
							show_value(issue.custom_value_for(c.custom_field))
						end
					else
						case c.name
							when :done_ratio
								fmt.number_format = "0%"
								(Float(issue.send(c.name)))/100
							when :description
								descr_str = '' 
								issue.description.to_s.each_char do |c_a|
									if c_a != "\r"
										descr_str << c_a
									end
								end
								descr_str
						when :history
                hist_str = '' 
                issue_updates = issue.journals.find(
                          :all, :include => [:user, :details],
                          :order => "#{Journal.table_name}.created_on ASC")
                for journal in issue_updates                    
                    hist_str << format_time(journal.created_on) + " - " + journal.user.name
                    hist_str << "\n"                    
                    for detail in journal.details
                      hist_str <<  " - " + show_detail(detail, true)
                      hist_str << "\n" unless detail == journal.details.last
                    end
                    if journal.notes?
                      hist_str << "\n" unless journal.details.empty?
                      hist_str << journal.notes.to_s
                    end
                    hist_str << "\n" unless journal == issue_updates.last
                  end
                hist_str
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
									issue.watcher_users.each do |user|
										rel_str << user.to_s
										rel_str << "\n" unless user == issue.watcher_users.last
									end
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
							when :project
								last_prj = issue.send(c.name)
								last_prj
							when :start_date, :due_date, :updated_on, :created_on
								fmt.number_format = date_format
								c.value(issue)
						else							
					 		issue.respond_to?(c.name) ? issue.send(c.name) : c.value(issue)
						end
					end
					
					value = ['Time', 'Date', 'Fixnum', 'Float', 'Integer', 'String', 'String'].include?(v.class.name) ? v : v.to_s
					row.set_format(j+1, fmt)
					lf_pos = get_value_width(value)
					columns_width[j+1] = lf_pos unless columns_width[j+1] >= lf_pos
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
		
		def init_header_columns(sheet1,columns)
			
			columns_width = [1]
			sheet1.row(0).replace ["#"]
			
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
					end
				end

				sheet1.column(idx+1).default_format = Spreadsheet::Format.new(opt) unless opt.empty?
				columns_width[idx+1] = width unless columns_width[idx+1] >= width
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

			if ['Time', 'Date'].include?(value.class.name)
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
