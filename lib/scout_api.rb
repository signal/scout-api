require 'rubygems'
require 'hashie'
require 'httparty'
require 'nokogiri'
require 'cgi'
require 'scout_api/version'
require 'scout_api/account'
require 'scout_api/server'
require 'scout_api/plugin'
require 'scout_api/trigger'
require 'scout_api/alert'
require 'scout_api/group.rb'
require 'scout_api/metric.rb'
require 'scout_api/person'
require 'scout_api/metric_proxy'
require 'scout_api/metric_calculation'


module Scout
  class Error < RuntimeError
  end
end
