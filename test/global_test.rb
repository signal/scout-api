require File.expand_path('../test_helper.rb', __FILE__)

class GlobalTest < Test::Unit::TestCase
  def setup
    @scout_scout = ScoutScout.new('account', 'username', 'password')
  end
  
  def test_version
    assert ScoutScout::VERSION.is_a?(String)
  end
  
  def test_init
    assert_equal 'account', @scout_scout.class.account
    assert @scout_scout.class.default_options[:basic_auth] == { :username => 'username', :password => 'password' }
  end
  
  def test_alerts
    @scout_scout.stub_get('activities.xml')
    activities = @scout_scout.alerts
    assert activities.first.is_a?(ScoutScout::Alert)
    assert_equal 2, activities.size
    activities.each do |activity|
      assert activity.title =~ /Passenger/
    end
  end
      
end