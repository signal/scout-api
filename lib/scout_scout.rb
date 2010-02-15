require 'hashie'
require 'httparty'
require 'cgi'
require 'scout_scout/version'
require 'scout_scout/server'
require 'scout_scout/descriptor'
require 'scout_scout/plugin'
require 'scout_scout/alert'
require 'scout_scout/cluster.rb'
require 'scout_scout/error.rb'
require 'scout_scout/metric.rb'

class ScoutScout
  include HTTParty
  base_uri 'https://scoutapp.com'
  format :xml
  mattr_inheritable :account

  def initialize(scout_account_name, username, password)
    self.class.account = scout_account_name
    self.class.basic_auth username, password
  end

  # Recent alerts across all servers on this account
  #
  # @return [Array] An array of ScoutScout::Alert objects
  def alerts
    response = self.class.get("/#{self.class.account}/activities.xml")
    response['alerts'].map { |alert| ScoutScout::Alert.new(alert) }
  end

  # All servers on this account
  #
  # @return [Array] An array of ScoutScout::Server objects
  def servers
    response = self.class.get("/#{self.class.account}/clients.xml")
    response['clients'].map { |client| ScoutScout::Server.new(client) }
  end

end