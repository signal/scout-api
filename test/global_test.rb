require File.expand_path('../test_helper.rb', __FILE__)

class GlobalTest < Test::Unit::TestCase
  def setup
    @scout = Scout::Account.new('account', 'username', 'password')
  end
  
  def test_version
    assert Scout::VERSION.is_a?(String)
  end
  
  def test_init
    assert_equal 'account', @scout.class.param
    assert @scout.class.default_options[:basic_auth] == { :username => 'username', :password => 'password' }
  end
  
  def test_alerts
    @scout.stub_get('activities.xml')
    activities = @scout.alerts
    assert activities.first.is_a?(Scout::Alert)
    assert_equal 2, activities.size
    activities.each do |activity|
      assert activity.title =~ /Passenger/
    end
  end
      
end