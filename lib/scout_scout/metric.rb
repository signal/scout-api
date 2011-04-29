class ScoutScout::Metric < Hashie::Mash
  attr_accessor :server, :plugin
  
  # Finds a single metric that meets the given conditions. Possible parameter formats:
  # 
  # ScoutScout::Metric.first(1) => Finds the metric with ID=1
  # ScoutScout::Metric.first(:name => 'request_rate') => Finds the first metric where name=~'request_rate'
  #
  # Use a MySQL-formatted Regex. http://dev.mysql.com/doc/refman/5.0/en/regexp.html
  #
  # @return [ScoutScout::Metric]
  def self.first(id_or_options)
    if id_or_options.is_a?(Hash)
      if name=id_or_options[:name]
        response = ScoutScout.get("/#{ScoutScout.account}/descriptors.xml?descriptor=#{CGI.escape(name)}")
        raise ScoutScout::Error, 'Not Found' if response['ar_descriptors'].nil?
        ScoutScout::Metric.new(response['ar_descriptors'].first)
      else
        raise ScoutScout::Error, "Invalid finder condition"
      end
    elsif id_or_options.is_a?(Fixnum)
      response = ScoutScout.get("/#{ScoutScout.account}/descriptors/#{id_or_options}.xml")
      ScoutScout::Metric.new(response['ar_descriptor'])
    else
      raise ScoutScout::Error, "Invalid finder condition"
    end
  end

  # Search for metrics. Typicial interaction is through the MetricProxy (ex: server.metrics.all)
  #
  # @return [Array] An array of ScoutScout::Metric objects
  def self.all(options = {})
    raise ScoutScout::Error, "A finder condition is required" if options.empty?
    response = ScoutScout.get("/#{ScoutScout.account}/descriptors.xml?name=#{CGI.escape(options[:name].to_s)}&ids=&plugin_ids=#{options[:plugin_ids]}&server_ids=#{options[:server_ids]}&group_ids=#{options[:group_ids]}")
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
  # * <tt>:start</tt>: The start time for grabbing metrics. Default is 1 hour ago. Times will be converted to UTC.
  # * <tt>:end</tt>: The end time for grabbing metrics. Default is NOW. Times will be converted to UTC.
  # * <tt>:aggregate</tt>: Whether the metrics should be added together or an average across each metric should be returned.
  #   Default is false. Note that total is not necessary equal to the value on each server * num of servers. :aggregate makes sense
  #   for metrics like throughput across a group of web servers where each server records its own throughput, but you are interested in
  #   the total throughput for the app.
  #
  # Examples:
  #
  # What is the average request time across my servers?
  # ScoutScout::Metric.average('request_time')
  #
  # What is the average TOTAL throughput across my servers?
  # ScoutScout::Metric.average('request_rate', :aggregate => true)
  #
  # How much average memory did my servers use yesterday?
  # ScoutScout::Metric.average('mem_used', :start => Time.now-(24*60*60)*2, :end => Time.now-(24*60*60))
  #
  # @return [Hash]
  def self.average(id_or_name,options = {})
    calculate('AVG',id_or_name,options)
  end
  
  # Find the maximum value of a metric by name (ex: 'last_minute').
  #
  # See +average+ for options and examples.
  #
  # @return [Hash]
  def self.maximum(id_or_name,options = {})
    calculate('MAX',id_or_name,options)
  end

  # Find the minimum value of a metric by name (ex: 'last_minute').
  #
  # See +average+ for options and examples.
  #
  # @return [Hash]
  def self.minimum(id_or_name,options = {})
    calculate('MIN',id_or_name,options)
  end
  
  # @return [Hash]
  def average(opts = {})
    self.class.average(identifier, options_for_relationship(opts))
  end
  alias avg average

  # @return [Hash]
  def maximum(opts = {})
     self.class.maximum(identifier, options_for_relationship(opts))
  end
  alias max maximum

  # @return [Hash]
  def minimum(opts = {})
     self.class.minimum(identifier, options_for_relationship(opts))
  end
  alias min minimum

  protected
  
  # Metrics are identified by either their given ID or their name.
  def identifier
    [:id] ? [:id] : name
  end
  
  def self.calculate(function,id_or_name,options = {})
    start_time,end_time=format_times(options)
    consolidate = options[:aggregate] ? 'SUM' : 'AVG'
    
    if id_or_name.is_a?(Fixnum)
      name = nil
      ids = id_or_name
    else
      name = id_or_name
      ids = nil
    end
    
    response = ScoutScout.get("/#{ScoutScout.account}/data/value?name=#{CGI.escape(name.to_s)}&ids=#{ids}&function=#{function}&consolidate=#{consolidate}&plugin_ids=#{options[:plugin_ids]}&server_ids=#{options[:server_ids]}&group_ids=#{options[:group_ids]}&start=#{start_time}&end=#{end_time}")

    if response['data']
      response['data']
    else
      raise ScoutScout::Error, response['error']
    end
  end

  def options_for_relationship(opts = {})
    relationship_options = {}
    if id?
      relationship_options[:ids] = id
    elsif plugin
      relationship_options[:plugin_ids] = plugin.id
    elsif server
      relationship_options[:server_ids] = server.id
    end
    opts.merge(relationship_options)
  end
  
   # API expects times in epoch.
   def self.format_times(options)
     options.values_at(:start,:end).map { |t| t ? t.to_i : nil }
   end
  
end