require File.expand_path('../test_helper.rb', __FILE__)

class MetricProxyTest < Test::Unit::TestCase
  def setup
    @scout_scout = ScoutScout.new('account', 'username', 'password')
  end
  
  def test_metrics
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    @scout_scout.stub_get('descriptors.xml?name=&ids=&plugin_ids=&server_ids=13431&group_ids=', 'descriptors.xml')
    metrics = server.metrics
    assert_equal 30, metrics.size
    assert metrics.first.is_a?(ScoutScout::Metric)
  end
  
end