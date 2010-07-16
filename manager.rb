require 'rubygems'
require 'sinatra'
require 'haml'
require 'active_record'
require 'sinatra/static_assets'
require 'less'
require "sinatra/reloader"

use Rack::Lint

configure do
  LOGGER = Logger.new("sinatra.log")
end
 
helpers do
  def logger
    LOGGER
  end
end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile =>  'gearman.sqlite3.db'
)

#Models
class Job < ActiveRecord::Base
  self.table_name = "gearman_queue"
  set_primary_key :unique_key
  named_scope :unique_functions, :group => "function_name"
end

# Methods
get '/' do
 @jobs = Job.all
 haml :index
end

get '/css/stylesheet.css' do
   content_type 'text/css', :charset => 'utf-8'
   less :stylesheet
end


#Jobs
get '/jobs' do
  @job_types = Job.unique_functions
  @jobs = Job.all
  haml :'jobs/index'
end

get '/jobs/new' do
  @job = Job.new
  haml :'jobs/new'
end

post '/jobs' do
  @job = Job.new(params[:post])
  if @job.save
    redirect "/jobs/#{@job.id}"
  else
    "There was a problem saving that..."
  end
end

post '/jobs/update/:id' do
  @job = Job.find(params[:id])
  logger.debug params.inspect
  @job.update_attributes(params[:job])
  redirect "/jobs/show/#{@job.unique_key}"
end

get '/jobs/:function_name' do
  @function_name = params[:function_name]
  @jobs = Job.find(:all, :conditions => ['function_name = ?', params[:function_name]], :order => 'when_to_run DESC')
  haml :'jobs/list'
end

get '/jobs/show/:id' do
  @job = Job.find(params[:id])
  @jobtimestr = Time.at(@job.when_to_run).strftime('%B %d, %Y @ %H:%M:%S %p')
  @priorities = {
    0 => 'High',
    1 => 'Normal', 
    2 => 'Low',
  }
  haml :'jobs/show'
end

__END__

@@ layout
%html
  %head
    %title Gearman Job Queue
    %meta{"http-equiv"=>"Content-Type", 
       :content=>"text/html; charset=utf-8"}/
    = stylesheet_link_tag '/css/stylesheet.css'

  %h1 Gearman manager
  = yield
