class ScoutScout::Metric < Hashie::Mash
  attr_accessor :server, :plugin

  # Search for metrics by matching name and server hostname.
  #
  # Options:
  #
  # - :name => The metric name to match (ex: 'disk_used')
  # - :host => The host name to match
  #
  # @return [Array] An array of ScoutScout::Metric objects
  def self.all(options = {})
    response = ScoutScout.get("/#{ScoutScout.account}/descriptors.xml?descriptor=#{CGI.escape(options[:name] || String.new)}&host=#{options[:host]}")
    response['ar_descriptors'] ? response['ar_descriptors'].map { |descriptor| ScoutScout::Metric.new(descriptor) } : Array.new
  end
  
  # Find the average value of a metric by name (ex: 'disk_used'). If the metric couldn't be found AND/OR
  # hasn't reported since +options[:start]+, a ScoutScout::Error is raised.
  #
  # A 3-element Hash is returned with the following keys:
  # * value
  # * units
  # * label
  #
  # Options:
  #
  # * <tt>:host</tt>: Only selects metrics from servers w/hostnames matching this pattern.
  #   Use a MySQL-formatted Regex. http://dev.mysql.com/doc/refman/5.0/en/regexp.html
  # * <tt>:start</tt>: The start time for grabbing metrics. Default is 1 hour ago. Times will be converted to UTC.
  # * <tt>:end</tt>: The end time for grabbing metrics. Default is NOW. Times will be converted to UTC.
  # * <tt>:per_server</tt>: Whether the result should be returned per-server or an aggregate of the entire cluster.
  #   Default is false. Note that total is not necessary equal to the value on each server * num of servers.
  # Examples:
  #
  # How much memory are my servers using?
  # ScoutScout::Metric.average('mem_used')
  #
  # What is the average per-server load on my servers?
  # ScoutScout::Metric.average('cpu_last_minute', :per_server => true)
  #
  # How much disk space is available on our db servers?
  # ScoutScout::Metric.average('disk_avail',:host => "db[0-9]*.awesomeapp.com")
  #
  # How much memory did my servers use yesterday?
  # ScoutScout::Metric.average('mem_used', :start => Time.now-(24*60*60)*2, :end => Time.now-(24*60*60)*2)
  #
  # @return Hash
  def self.average(name,options = {})
    calculate('AVG',name,options)
  end
  
  # Find the maximum value of a metric by name (ex: 'last_minute').
  #
  # See +average+ for options and examples.
  #
  # @return Hash
  def self.maximum(name,options = {})
    calculate('MAX',name,options)
  end

  # Find the minimum value of a metric by name (ex: 'last_minute').
  #
  # See +average+ for options and examples.
  #
  # @return Hash
  def self.minimum(name,options = {})
    calculate('MIN',name,options)
  end
  
  # @return Hash
  def average(opts = {})
    self.class.average(name, options_for_relationship(opts))
  end

  # @return Hash
  def maximum(opts = {})
     self.class.maximum(name, options_for_relationship(opts))
  end

  # @return Hash
  def minimum(opts = {})
     self.class.minimum(name, options_for_relationship(opts))
  end

  protected
  
  def self.calculate(function,name,options = {})
    consolidate = options[:per_server] ? 'AVG' : 'SUM'
    start_time,end_time=format_times(options)
    response = ScoutScout.get("/#{ScoutScout.account}/data/value?descriptor=#{CGI.escape(name)}&function=#{function}&consolidate=#{consolidate}&host=#{options[:host]}&start=#{start_time}&end=#{end_time}")

    if response['data']
      response['data']
    else
      raise ScoutScout::Error, response['error']
    end
  end

  def options_for_relationship(opts = {})
    relationship_options = {}
    relationship_options[:host] = server.hostname if server
    opts.merge(relationship_options)
  end
  
   # API expects times in epoch.
   def self.format_times(options)
     options.values_at(:start,:end).map { |t| t ? t.to_i : nil }
   end
  
end