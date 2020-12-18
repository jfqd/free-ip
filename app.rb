# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'resolv'
require 'ipaddress'
require 'dotenv'
require 'erb'

Dotenv.load ".env.#{ENV["RACK_ENV"] || "production"}", '.env'

PLAIN_TEXT = {'Content-Type' => 'text/plain'}

set :database, Hash.new.tap { |hash|
  YAML::load( File.open('config/database.yml') ).each do |key, value|
    renderer = ERB.new(value)
    hash[key.to_sym] = renderer.result()
  end
}

configure do
  # http://recipes.sinatrarb.com/p/middleware/rack_commonlogger
  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file
end

class FreeIp < ActiveRecord::Base
  validates :ip,
            presence: true,
            uniqueness: { case_sensitive: false }
  validates :description,
            presence: false,
            format: {
              with: /\A[\w -]+\z/,
              message: "only allows letters, numbers and space"
            }
end

class String
  def blank?
    self == nil || self == ''
  end
end

# get a free ip by a given type
get '/get/:version/:routable/:description' do
  begin
    version = params[:version]
    routable = params[:routable]
    description = params[:description].blank? ? '' : params[:description]
    if version  == "ipv4" || version  == "ipv6" &&
       routable == "true" || routable == "false"
      ActiveRecord::Base.clear_active_connections!
      free_ip = FreeIp.where(active: false, version: version, routable: routable).
                       order(created_at: :asc).
                       first
      free_ip.active = true
      free_ip.description = params[:description]
      free_ip.save!
      halt 200, PLAIN_TEXT, "#{free_ip.ip}\n"
    else
      raise "wrong ip-type"
    end
  rescue Exception => e
    logger.warn "[free-ip] Rescue: #{e.message}"
    halt 400
  end
end

put '/release/:ip' do
  begin
    ip = params[:ip]
    # validate ip address and get version
    version = case ip
      when Resolv::IPv4::Regex then :ipv4
      when Resolv::IPv6::Regex then :ipv6
    else
      raise "wrong ip-type"
    end
    # ipv6-address need to be compressed
    if version == :ipv6 && ip !~ Resolv::IPv6::Regex_CompressedHex
      ip = IPAddress::IPv6.compress ip
    end
    ActiveRecord::Base.clear_active_connections!
    free_ip = FreeIp.where(ip: ip).first
    free_ip.active = false
    free_ip.description = "-"
    free_ip.save!
    halt 200, PLAIN_TEXT, "#{free_ip.ip} released\n"
  rescue Exception => e
    logger.warn "[free-ip] Rescue: #{e.message}"
    halt 400
  end
end

get "/robots.txt" do
  %{User-agent: *\nDisallow: /}
end

get '/ping' do
  halt 200, PLAIN_TEXT, 'pong'
end

get "/*" do
  halt 403
end