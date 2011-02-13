require 'redmine'
#require_dependency 'issues_controller' 

module IssuesControllerXLSPatch

  def self.included(base) # :nodoc:    
    base.send(:include, InstanceMethods)     
    base.class_eval do      
      unloadable
# have to include all the bunch from original controller because of Rails implementation
# of before_filter :authorize
			if Redmine::VERSION::MAJOR <= 1
				before_filter :authorize, :except => [:index, :changes, :preview, :context_menu, :xls_export_action]
			else
				before_filter :authorize, :except => [:index, :xls_export_action]
			end
		  before_filter :find_optional_project_xls, :only => [:xls_export_action]
		  
      alias_method_chain :index, :xls_export
    end
  end

	module InstanceMethods

		include IssuesHelper
		include Redmine::Export::XLS
		
	  def index_with_xls_export
			if params[:format] != 'xls'
				return index_without_xls_export
			end
			
			if retrieve_xls_export_data
				export_name = get_xls_export_name
				send_data(issues_to_xls2(@issues, @project, @query, @settings), :type => :xls, :filename => export_name)
			else
	      # Send html if the query is not valid
	      render(:template => 'issues/index.rhtml', :layout => !request.xhr?)
			end
	  end
	  
		def xls_export_action
			if request.post?
				@settings = params[:settings]
				if retrieve_xls_export_data(@settings)
					export_name = get_xls_export_name
					send_data(issues_to_xls2(@issues, @project, @query, @settings), :type => :xls, :filename => export_name)
				else
					redirect_to :action => 'index', :project_id => @project				
				end
			end
			@settings=Setting["plugin_redmine_xls_export"]
		end

private

		def retrieve_xls_export_data(settings=nil)
			params[:query_id]=session[:query][:id] if !session[:query].nil? && !session[:query][:id].blank?
			if !params[:query_id].blank? && !session['issues_index_sort'].blank?
				user_sort_string=session['issues_index_sort']
				retrieve_query
				session['issues_index_sort']=user_sort_string if session['issues_index_sort'].blank?
			else
				retrieve_query
			end
			params[:sort]=session['issues_index_sort'] if params[:sort].nil? && !session['issues_index_sort'].nil?
# taken from issues_controller directly
# start of original code
	    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
	    sort_update(@query.sortable_columns)
#	    sort_update({'id' => "#{Issue.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
	    
	    if @query.valid?
# string was modified	    	
	    	limit = ( settings && settings[:issues_limit].to_i>0 ? settings[:issues_limit].to_i : Setting.issues_export_limit.to_i )
#	      
	      @issue_count = @query.issue_count
	      @issue_pages = ActionController::Pagination::Paginator.new self, @issue_count, limit, params['page']
	      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
	                              :order => sort_clause, 
	                              :offset => @issue_pages.current.offset, 
	                              :limit => limit)
	      @issue_count_by_group = @query.issue_count_by_group
# end of original code	      
	      @settings=Setting["plugin_redmine_xls_export"] unless settings

	      return true
	    end
	    	
	    return false
	  rescue ActiveRecord::RecordNotFound
	    render_404
		end
		
		def find_optional_project_xls
			@project = Project.find(params[:project_id]) unless params[:project_id].blank?
			allowed = User.current.allowed_to?({:controller => params[:controller], :action => :index}, @project, :global => true)
			allowed ? true : deny_access
		rescue ActiveRecord::RecordNotFound
			render_404
		end
		
		def get_xls_export_name
			return "export.xls" unless !@settings['export_name'].blank?
			return "#{@settings['export_name']}.xls" unless @settings['generate_name'] == '1'
			
			fnm = ''
			fnm << (@project ? @project.to_s : l(:label_project_plural)).gsub(' ','_') << '_' << @settings['export_name'] << '.xls'
			
			return fnm
		end

	end

end
