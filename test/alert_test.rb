require File.expand_path('../test_helper.rb', __FILE__)

class AlertTest < Test::Unit::TestCase
  def setup
    @scout = Scout::Account.new('account', 'username', 'password')
    @scout.stub_get('activities.xml')
    @scout.stub_get('clients/24331.xml', 'client.xml')
  end

  def test_server
    activities = @scout.alerts
    assert activities.first.server.is_a?(Scout::Server)
  end
  
  def test_plugin
    @scout.stub_get('clients/13431/plugins/122761.xml', 'plugin_data.xml')
    activities = @scout.alerts
    assert activities.first.plugin.is_a?(Scout::Plugin)
  end
end