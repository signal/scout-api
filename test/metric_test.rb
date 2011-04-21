require File.expand_path('../test_helper.rb', __FILE__)

class MetricTest < Test::Unit::TestCase
  def setup
    @scout_scout = ScoutScout.new('account', 'username', 'password')
  end
  
  def test_should_find_all_metrics
    @scout_scout.stub_get('descriptors.xml?descriptor=&host=&','descriptors.xml')
    metrics = ScoutScout::Metric.all
    assert_equal ScoutScout::Metric, metrics.first.class
    assert_equal 30, metrics.size
  end
  
  def test_should_get_klass_average
    @scout_scout.stub_get('data/value?descriptor=cpu_last_minute&function=AVG&consolidate=SUM&host=&start=&end=&','data.xml')
    result = ScoutScout::Metric.average('cpu_last_minute')
    assert result.is_a?(Hash)
    assert_equal '31.10', result['value']
  end
  
  def test_should_get_instance_average
    @scout_scout.stub_get('clients/13431.xml', 'client.xml')
    server = ScoutScout::Server.first(13431)
    @scout_scout.stub_get('clients/13431/plugins.xml', 'plugins.xml')
    plugins = server.plugins
    @scout_scout.stub_get('data/value?descriptor=passenger_process_active&function=AVG&consolidate=SUM&host=foobar.com&start=&end=&','data.xml')
    result = plugins.first.metrics.first.average
    assert_equal '31.10', result['value']
  end
  
end