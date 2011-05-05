# Groups represent a collection of servers. 
# They can be created in the Scout UI to put similar servers together (ex: Web Servers, Database Servers).
class Scout::Group < Hashie::Mash
  # Retrieve metric information. See {Scout::Metric.average} for a list of options for the calculation
  # methods (average, minimum, maximum).
  # 
  # Examples:
  # 
  #  # All metrics associated with this group.
  #  Scout::Group.metrics
  # 
  #  # Metrics with name =~ 'Memory Used' across all servers in this group.
  #  Scout::Group.metrics.all(:name => 'Memory Used')
  # 
  #  # Average value of metrics with name =~ 'Memory Used' across all servers in the group
  #  Scout::Group.metrics.average(:name => 'Memory Used')
  # 
  #  # Maximum value ...
  #  Scout::Group.metrics.maximum(:name => 'Memory Used')
  # 
  #  # Minimum value ... 
  #  Scout::Group.metrics.minimum(:name => 'Memory Used')
  #
  #  # Sum metrics, then take average
  #  Scout::Group.metrics.average(:name => 'request_rate', :aggregate => true)
  #
  #  # Retrieve data starting @ 5 hours ago ending at 2 hours ago
  #  Scout::Group.metrics.average(:name => 'request_rate', :start => Time.now.utc-5*3600, :end => Time.now.utc-2*3600)
  #
  #  # An array of time series values over the past hour
  #  Scout::Group.metrics.average(:name => 'Memory Used').to_array
  #
  #  # A Url to a Google Sparkline Chart
  #  Scout::Group.metrics.average(:name => 'Memory Used').to_sparkline
  attr_reader :metrics

  def initialize(hash) #:nodoc:
    @metrics = Scout::MetricProxy.new(self)
    super(hash)
  end
  
  # Finds the first group that meets the given conditions. Possible parameter formats:
  # 
  #  Scout::Group.first
  #  Scout::Group.first(1)
  #  Scout::Group.first(:name => 'db slaves')
  #
  # For the <tt>:name</tt>, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  #
  # @return [Scout::Group]
  def self.first(id_or_options = nil)
    if id_or_options.nil?
      response = Scout::Account.get("/groups.xml?limit=1")
      Scout::Group.new(response['groups'].first)
    elsif id_or_options.is_a?(Hash)
      if name=id_or_options[:name]
        response = Scout::Account.get("/groups.xml?name=#{CGI.escape(name)}")
        raise Scout::Error, 'Not Found' if response['groups'].nil?
        Scout::Group.new(response['groups'].first)
      else
        raise Scout::Error, "Invalid finder condition"
      end
    elsif id_or_options.is_a?(Fixnum)
      response = Scout::Account.get("/groups/#{id_or_options}.xml")
      Scout::Group.new(response['group'])
    else
      raise Scout::Error, "Invalid finder condition"
    end
  end
  
  # Finds all groups that meets the given conditions. Possible parameter formats:
  # 
  #  Scout::Group.all
  #  Scout::Group.all(:name => 'web')
  #
  # For the <tt>:name</tt>, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  #
  # @return [Array] An array of Scout::Group objects
  def self.all(options = {})
    if name=options[:name]
      response = Scout::Account.get("/groups.xml?name=#{CGI.escape(name)}")
    elsif options.empty?
      response = Scout::Account.get("/groups.xml")
    else
      raise Scout::Error, "Invalid finder condition"
    end
    response['groups'] ? response['groups'].map { |g| Scout::Group.new(g) } : Array.new
  end
  
end