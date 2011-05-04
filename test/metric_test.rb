require File.expand_path('../test_helper.rb', __FILE__)

class MetricTest < Test::Unit::TestCase
  def setup
    @scout = Scout::Account.new('account', 'username', 'password')
  end
  
  def test_should_find_all_metrics
    @scout.stub_get('descriptors.xml?name=blah&ids=&plugin_ids=&server_ids=&group_ids=','descriptors.xml')
    metrics = Scout::Metric.all(:name=>'blah')
    assert_equal Scout::Metric, metrics.first.class
    assert_equal 30, metrics.size
  end
  
  def test_should_get_klass_average
    @scout.stub_get('data/value?name=cpu_last_minute&ids=&function=AVG&consolidate=AVG&plugin_ids=&server_ids=&group_ids=&start=&end=','data.xml')
    result = Scout::Metric.average('cpu_last_minute')
    assert result.is_a?(Hash)
    assert_equal '31.10', result['value']
  end
  
  def test_should_get_instance_average
    @scout.stub_get('clients/13431.xml', 'client.xml')
    server = Scout::Server.first(13431)
    @scout.stub_get('clients/13431/plugins.xml', 'plugins.xml')
    plugins = server.plugins
    @scout.stub_get('data/value?name=passenger_process_active&ids=&function=AVG&consolidate=AVG&plugin_ids=&server_ids=&group_ids=&start=&end=','data.xml')
    result = plugins.first.metrics.first.average
    assert_equal '31.10', result['value']
  end
  
end