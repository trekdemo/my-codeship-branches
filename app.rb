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
  'Usage:'
end

get '/:uuid' do |uuid|
  get_repository_branches(uuid)
end

# Add watched branches
post '/:uuid' do |uuid|
  set_repository_branches(uuid, params[:branches].to_s.split(/[\s,;]+/))
end

private
def get_repository_branches(uuid)
  $redis.smembers(project_key(uuid)).inspect
end

def set_repository_branches(uuid, branches = [])
  $redis.sadd(project_key(uuid), Array(branches).map(&:to_s))
end

def project_key(uuid)
  [uuid, 'branches'].join(':')
end
