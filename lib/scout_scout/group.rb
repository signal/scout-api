# Groups represent a collection of servers. 
# They can be created in the Scout UI to put similar servers together (ex: Web Servers, Database Servers).
class ScoutScout::Group < Hashie::Mash
  # Retrieve metric information. See ScoutScout::Metric#average for a list of options for the calculation
  # methods (average, minimum, maximum).
  # 
  # Examples:
  # 
  # * <tt>ScoutScout::Group.metrics => All metrics associated with this group.</tt>
  # * <tt>ScoutScout::Group.metrics.all(:name => 'mem_used') => Metrics with name =~ 'mem_used' across all servers in this group.</tt>
  # * <tt>ScoutScout::Group.metrics.average(:name => 'mem_used') => Average value of metrics with name =~ 'mem_used' across all servers in the group.</tt> 
  # * <tt>ScoutScout::Group.metrics.maximum(:name => 'mem_used')</tt>
  # * <tt>ScoutScout::Group.metrics.minimum(:name => 'mem_used')</tt>
  # * <tt>ScoutScout::Group.metrics.average(:name => 'request_rate', :aggregate => true) => Sum metrics, then take average</tt>
  # * <tt>ScoutScout::Group.metrics.average(:name => 'request_rate', :start => Time.now.utc-5*3600, :end => Time.now.utc-2*3600) => Retrieve data starting @ 5 hours ago ending at 2 hours ago</tt>
  attr_reader :metrics

  def initialize(hash) #:nodoc:
    @metrics = ScoutScout::MetricProxy.new(self)
    super(hash)
  end
  
  # Finds the first group that meets the given conditions. Possible parameter formats:
  # 
  # * <tt>ScoutScout::Group.first(1)</tt>
  # * <tt>ScoutScout::Group.first(:name => 'db slaves')</tt>
  #
  # For the <tt>:name</tt>, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  #
  # @return [ScoutScout::Group]
  def self.first(id_or_options)
    if id_or_options.is_a?(Hash)
      if name=id_or_options[:name]
        response = ScoutScout.get("/#{ScoutScout.account}/groups.xml?name=#{CGI.escape(name)}")
        raise ScoutScout::Error, 'Not Found' if response['groups'].nil?
        ScoutScout::Server.new(response['groups'].first)
      else
        raise ScoutScout::Error, "Invalid finder condition"
      end
    elsif id_or_options.is_a?(Fixnum)
      response = ScoutScout.get("/#{ScoutScout.account}/groups/#{id_or_options}.xml")
      ScoutScout::Group.new(response['group'])
    else
      raise ScoutScout::Error, "Invalid finder condition"
    end
  end
  
  # Finds all groups that meets the given conditions. Possible parameter formats:
  # 
  # * <tt>ScoutScout::Group.all</tt>
  # * <tt>ScoutScout::Group.all(:name => 'web')</tt>
  #
  # For the <tt>:name</tt>, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  #
  # @return [Array] An array of ScoutScout::Group objects
  def self.all(options = {})
    if name=options[:name]
      response = ScoutScout.get("/#{ScoutScout.account}/groups.xml?name=#{name}")
    elsif options.empty?
      response = ScoutScout.get("/#{ScoutScout.account}/groups.xml")
    else
      raise ScoutScout::Error, "Invalid finder condition"
    end
    response['groups'] ? response['groups'].map { |g| ScoutScout::Group.new(g) } : Array.new
  end
  
end