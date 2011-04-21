require File.expand_path('../test_helper.rb', __FILE__)

class AlertTest < Test::Unit::TestCase
  def setup
    @scout_scout = ScoutScout.new('account', 'username', 'password')
    @scout_scout.stub_get('activities.xml')
    @scout_scout.stub_get('clients/24331.xml', 'client.xml')
  end

  def test_server
    activities = @scout_scout.alerts
    assert activities.first.server.is_a?(ScoutScout::Server)
  end
  
  def test_plugin
    @scout_scout.stub_get('clients/13431/plugins/122761.xml', 'plugin_data.xml')
    activities = @scout_scout.alerts
    assert activities.first.plugin.is_a?(ScoutScout::Plugin)
  end
end