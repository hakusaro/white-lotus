#coding: utf-8

require 'sinatra'
require 'sinatra/session'
require 'sinatra/partial'
require 'omniauth'
require 'omniauth-openid'
require 'pry'
require 'openid/store/filesystem'
require 'awesome_print'
require 'yaml'
require 'sequel'
require 'rest_client'

if (ENV['environment'] ? ENV['environment'].to_sym : :dev == :production) then
  puts 'Server is running in production mode but nobody put anything different here.'
  set :environment => :production
else
  set :environment => :development
end

if (settings.environment == :production) then
  set :logging => false,
    :dump_errors => false,
    :raise_errors => false
else
  set :logging => true,
    :dump_errors => true,
    :raise_errors => true,
    :session_secret => '\]$?=?SndTw%`l\ps&cb P2v|U)Maka4a*o[RW*yH{OH9/LwsdfD',
    :bind => '0.0.0.0',
    :port => 4567

  temp_config = ""
  File.open('config.yaml', 'r').each_line do |line|
    temp_config << line
  end
  app_config = YAML.load(temp_config)

  set :db_url => app_config['db_url'] or 'sqlite://database.db'
  set :db_type => app_config['db_type'].to_sym or :sqlite
end

if (settings.db_type == :sqlite) then
  DB = Sequel.connect(settings.db_url)
else
  DB = Sequel.connect(settings.db_url)
end

set :partial_template_engine => :erb

use OmniAuth::Builder do
  provider :open_id, :name => 'steam', 'identifier' => 'http://steamcommunity.com/openid'
end

require_relative 'routes/init'
require_relative 'models/init'
