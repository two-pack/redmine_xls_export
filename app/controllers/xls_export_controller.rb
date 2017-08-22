require 'xlse_asset_helpers'
require_dependency 'xls_export'
begin
  require 'zip/zip'
rescue LoadError
  ActionController::Base::logger.info 'XLS export controller: rubyzip gem not available'
end

class XlsExportController < ApplicationController
  unloadable

  ZIP_FILENAMES_ENCODING = 'cp866'
  ZIP_FILENAMES_ENCODING_FALLBACK = 'cp850'

  ATTACHMENTS_FOLDER = 'attachments'
  NOT_FOUND_ATTACHMENTS_FOLDER = 'attachments'
  JOURNALS_FOLDER = 'journals'

  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper
  helper :issues
  include IssuesHelper
  include Redmine::Export::XLS
  helper :custom_fields
  include CustomFieldsHelper

  before_action :find_optional_project_xls

  def index
    @issues_export_offset=params[:issues_export_offset].to_i || 0
    if request.post?
      @settings = params[:settings]
      @issues_export_offset=params[:issues_export_offset].to_i || 0
      if retrieve_xls_export_data(@settings)
        export_name = get_xls_export_name(@settings)
        send_data(export_to_string(export_name), :type => export_name[1].to_sym, :filename => filename_for_content_disposition(export_name.join(".")))
      else
        redirect_to :controller => 'issues', :action => 'index', :project_id => @project
      end
    end
    @settings=XLSE_AssetHelpers::settings
  end

  def export_current
    @settings=XLSE_AssetHelpers::settings
    @issues_export_offset=params[:issues_export_offset].to_i || 0
    if retrieve_xls_export_data(@settings)
      export_name = get_xls_export_name(@settings)
      send_data(export_to_string(export_name), :type => export_name[1].to_sym, :filename => filename_for_content_disposition(export_name.join(".")))
    else
      # Send html if the query is not valid
      render(:template => 'issues/index', :layout => !request.xhr?)
    end
  end

protected
  def find_optional_project_xls
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
    allowed = User.current.allowed_to?({:controller => 'issues', :action => 'index'}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def query_issues(export_offset, limit)
    options = {:order => sort_clause, :offset => export_offset, :limit => limit}
    if (Redmine::VERSION::MAJOR <= 3) && (Redmine::VERSION::MINOR <= 3) && (Redmine::VERSION::BRANCH != 'devel') then
      options.merge!({:include => [:assigned_to, :tracker, :priority, :category, :fixed_version]})
    end
    @query.issues(options)
  end

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
    sort_init(@query.sort_criteria.empty? ? [%w(id desc)] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    if @query.valid?
      @issue_count = @query.issue_count
      if @issue_count >0
        export_offset = @issues_export_offset >= @issue_count ? @issue_count-1 : @issues_export_offset
        limit = ( settings && settings[:issues_limit].to_i>0 ? settings[:issues_limit].to_i : Setting.issues_export_limit.to_i )
#        @issue_pages = ActionController::Pagination::Paginator.new self, @issue_count, limit, params['page']
        @issues = query_issues(export_offset, limit)
#        @issue_count_by_group = @query.issue_count_by_group
# end of original code
        @settings=XLSE_AssetHelpers::settings unless settings
      end
      return true
    end

    return false
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def zip_export_file?(settings)
    settings['export_attached'] == '1' ||
    settings['separate_journals'] == '1' ||
    settings['export_status_histories'] == '1'
  end

  def get_xls_export_name(settings = @settings)
    ext= zip_export_file?(settings) ? 'zip' : 'xls'
    return ["export",ext] if @settings['export_name'].blank?
    return ["#{@settings['export_name']}",ext] unless @settings['generate_name'] == '1'

    fnm = ''
    fnm << Date.today.strftime("%y%m%d") << '_'
    fnm << (@project ? @project.to_s : l(:label_project_plural)).gsub(' ','_') << '_' << @settings['export_name']

    return [fnm,ext]
  end

  def export_to_string(export_name)
    issues_xls=issues_to_xls2(@issues, @project, @query, @settings)
    return issues_xls unless export_name[1] == 'zip' && defined?(Zip::ZipOutputStream::write_buffer)

    zip_file=Zip::ZipOutputStream::write_buffer do |zip_stream|
      zip_stream.put_next_entry("#{export_name[0]}.xls",nil,nil,Zip::ZipEntry::DEFLATED,Zlib::BEST_COMPRESSION)
      zip_stream.write(issues_xls)
      @issues.each do |issue|
        if @settings['export_attached'] == '1'
          retrieve_attachments_list(issue).each do |attach|
            file=begin
              File.open(attach[:object].diskfile,'rb')
            rescue
              nil
            end
            zip_stream.put_next_entry("#{file ? "#{ATTACHMENTS_FOLDER}/" : "#{NOT_FOUND_ATTACHMENTS_FOLDER}/"}%05i/#{create_zip_filename(attach)}" % [issue.id],nil,nil,Zip::ZipEntry::DEFLATED,Zlib::BEST_COMPRESSION)
            unless file
              file=StringIO.new('')
              file.write("\n")
              file.rewind
            end
            zip_stream.write(file.read)
          end
        end
        if @settings['separate_journals'] == '1'
          journal_xls=journal_details_to_xls(issue, @settings)
          if journal_xls
            zip_stream.put_next_entry("#{JOURNALS_FOLDER}/%05i_journal_details.xls" % [issue.id],nil,nil,Zip::ZipEntry::DEFLATED,Zlib::BEST_COMPRESSION)
            zip_stream.write(journal_xls)
          end
        end
      end

      if @settings['export_status_histories'] == '1'
        status_histories_xls = status_histories_to_xls(@issues, @settings)
        if status_histories_xls
          zip_stream.put_next_entry("status_histories.xls",nil,nil,Zip::ZipEntry::DEFLATED,Zlib::BEST_COMPRESSION)
          zip_stream.write(status_histories_xls)
        end
      end
    end

    zip_file.string
  end

  def retrieve_attachments_list(issue)
    attachments=[]
    if issue.attachments
      filenames_hash={}
      issue.attachments.each do |a|
        filenames_hash[a.filename.downcase] = [] if filenames_hash[a.filename.downcase].blank?
        filenames_hash[a.filename.downcase] << a
      end

      filenames_hash.each_value do |a|
        a.sort! do |v1,v2|
          v2.created_on <=> v1.created_on
        end
      end

      filenames_a=filenames_hash.to_a.sort do |v1,v2|
        v1[0] <=> v2[0]
      end

      filenames_a.each do |f|
        f[1].each_with_index do |a,idx|
          attachments << { :object => a, :idx => idx}
        end
      end
    end
    attachments
  end

  def create_zip_filename(attach)
    new_name=''
    if attach[:idx] == 0
      new_name << attach[:object].filename
    else
      if attach[:object].filename =~ /^(.+)\.([^ .]+?)$/
        new_name << "#{$1}(%02i).#{$2}" % [attach[:idx].to_i]
      else
        new_name << "#{attach[:object].filename}(%02i)" % [attach[:idx].to_i]
      end
    end

    begin
      Iconv.iconv(ZIP_FILENAMES_ENCODING,'utf-8', new_name).join
    rescue
      begin
        Iconv.iconv(ZIP_FILENAMES_ENCODING_FALLBACK,'utf-8', new_name).join
      rescue
        new_name
      end
    end
  end

end
