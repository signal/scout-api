require File.expand_path('../test_helper.rb', __FILE__)

class PluginTest < Test::Unit::TestCase
  def setup
    @scout = Scout::Account.new('account', 'username', 'password')
  end
  
  def test_truth
    assert true
  end
  
end