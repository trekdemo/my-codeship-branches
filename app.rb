require 'bundler/setup'
require 'sinatra'
require 'codeship'
require 'redis'

configure :production do
  $redis = Redis.new(url: ENV["REDISCLOUD_URL"], driver: :hiredis)
end

configure :development, :test do
  $redis = Redis.new
end

get '/' do
  haml :index
end

get '/:uuid' do |uuid|
  branches = get_repository_branches(uuid)
  @statuses = branches.each_with_object({}) do |branch, statuses|
    statuses[branch] = Codeship::Status.new(uuid, branch: branch)
  end

  haml :project_status
end

# Add watched branches
post '/:uuid' do |uuid|
  set_repository_branches(uuid, params[:branches].to_s.split(/[\s,;]+/))
end

private
def get_repository_branches(uuid)
  $redis.smembers(project_key(uuid))
end

def set_repository_branches(uuid, branches = [])
  $redis.sadd(project_key(uuid), Array(branches).map(&:to_s))
end

def project_key(uuid)
  [uuid, 'branches'].join(':')
end

__END__

@@ layout
!!!
%html
  %head
    <link rel="stylesheet" href="http://yui.yahooapis.com/pure/0.5.0/pure-min.css">
  %body
    = yield

@@ index
%div.title Hello world.

@@ project_status
.branches
  - @statuses.each_pair do |branch, status|
    %dt= branch
    %dd
      = status.status
      %img{src: "http://www.codeship.io/projects/#{params[:uuid]}/status?branch=#{branch}"}
