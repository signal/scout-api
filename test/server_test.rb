require File.expand_path('../test_helper.rb', __FILE__)

class ServerTest < Test::Unit::TestCase
  def setup
    @scout_scout = ScoutScout.new('account', 'username', 'password')
  end
  
  def test_first_by_id
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    assert server.is_a?(ScoutScout::Server)
    assert_equal 13431, server.id
    assert_equal 'FOOBAR', server.key
  end
  
  def test_first_by_hostname
    @scout_scout.stub_get('clients.xml?host=foo.awesome.com', 'client_by_hostname.xml')
    server = ScoutScout::Server.first('foo.awesome.com')
    assert server.is_a?(ScoutScout::Server)
    assert_equal 'FOOBAR', server.key
  end
  
  def test_plugin
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    @scout_scout.stub_get('clients/13431/plugins/122681.xml', 'plugin_data.xml')
    plugin = server.plugin(122681)
    assert plugin.is_a?(ScoutScout::Plugin)
    assert_equal 122681, plugin.id
    
    assert plugin.metrics.first.is_a?(ScoutScout::Metric)
    assert_equal '31', plugin.metrics.first.value
    assert_equal 'passenger_process_active', plugin.metrics.first.name
  end
  
  def test_plugins
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    @scout_scout.stub_get('clients/13431/plugins.xml', 'plugins.xml')
    plugins = server.plugins
    
    assert_equal 2, plugins.size
    plugins.each do |plugin|
      assert plugin.name =~ /Passenger/
      assert_equal 11, plugin.metrics.size
    end
    
    assert plugins.first.is_a?(ScoutScout::Plugin)
  end
  
  def test_alerts
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    @scout_scout.stub_get('clients/13431/activities.xml', 'activities.xml')
    activities = server.alerts
    assert_equal 2, activities.size
    activities.each do |activity|
      assert activity.title =~ /Passenger/
    end
    assert activities.first.is_a?(ScoutScout::Alert)
  end
  
  def test_triggers
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    @scout_scout.stub_get('clients/13431/triggers.xml', 'triggers.xml')
    triggers = server.triggers
    assert_equal 3, triggers.size
    triggers.each do |trigger|
      assert_equal 'peak', trigger.simple_type
    end
    assert triggers.first.is_a?(ScoutScout::Trigger)
  end
  
  def test_metrics
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    @scout_scout.stub_get('descriptors.xml?descriptor=&host=foobar.com&', 'descriptors.xml')
    metrics = server.metrics
    assert_equal 30, metrics.size
    assert metrics.first.is_a?(ScoutScout::Metric)
  end
  
  def test_create
    @scout_scout.stub_post('clients.xml?client[copy_plugins_from_client_id]=&client[name]=sweet%20new%20server', 
    'client.xml', {:id => '1234'})
    @scout_scout.stub_get('clients/1234.xml', 'client.xml')
    server = ScoutScout::Server.create('sweet new server')
    assert_equal 13431, server.id
  end
  
  def test_delete
    @scout_scout.stub_delete('clients/1234.xml','client.xml', {'status' => '200 OK'})
    assert ScoutScout::Server.delete(1234)
  end
  
end