class Scout::Metric < Hashie::Mash
  attr_accessor :server, :plugin
  
  def initialize(hash) #:nodoc:
    super(hash)
    @avg_calc = Scout::MetricCalculation.new(self,:AVG)
    @avg_calc.metric_name = identifier
    @min_calc = Scout::MetricCalculation.new(self,:MIN)
    @min_calc.metric_name = identifier
    @max_calc = Scout::MetricCalculation.new(self,:MAX)
    @max_calc.metric_name = identifier
  end
  
  # Finds a single metric that meets the given conditions. Possible parameter formats:
  # 
  # * <tt>Scout::Metric.first</tt> => Finds the metric
  # * <tt>Scout::Metric.first(1)</tt> => Finds the metric with ID=1
  # * <tt>Scout::Metric.first(:name => 'request_rate')</tt> => Finds the first metric where name=~'request_rate'
  #
  # For the <tt>:name</tt>, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  #
  # @return [Scout::Metric]
  def self.first(id_or_options = nil)
    if id_or_options.nil?
      response = Scout::Account.get("/descriptors.xml?limit=1")
      Scout::Metric.new(response['ar_descriptors'].first)
    elsif id_or_options.is_a?(Hash)
      if name=id_or_options[:name]
        response = Scout::Account.get("/descriptors.xml?name=#{CGI.escape(name)}")
        raise Scout::Error, 'Not Found' if response['ar_descriptors'].nil?
        Scout::Metric.new(response['ar_descriptors'].first)
      else
        raise Scout::Error, "Invalid finder condition"
      end
    elsif id_or_options.is_a?(Fixnum)
      response = Scout::Account.get("/descriptors/#{id_or_options}.xml")
      Scout::Metric.new(response['ar_descriptor'])
    else
      raise Scout::Error, "Invalid finder condition"
    end
  end

  # Search for metrics. MetricProxy uses this method to search for metrics. Refer to MetricProxy#all.
  #
  # @return [Array] An array of Scout::Metric objects
  def self.all(options = {})
    raise Scout::Error, "A finder condition is required" if options.empty?
    response = Scout::Account.get("/descriptors.xml?name=#{CGI.escape(options[:name].to_s)}&ids=&plugin_ids=#{options[:plugin_ids]}&server_ids=#{options[:server_ids]}&group_ids=#{options[:group_ids]}")
    response['ar_descriptors'] ? response['ar_descriptors'].map { |descriptor| Scout::Metric.new(descriptor) } : Array.new
  end
  
  # Find the average value of a metric by ID or name (ex: <tt>'disk_used'</tt>). If the metric couldn't be found AND/OR
  # hasn't reported since <tt>options[:start]</tt>, a [Scout::Error] is raised.
  #
  # A 3-element Hash is returned with the following keys:
  # * <tt>:value</tt>
  # * <tt>:units</tt>
  # * <tt>:label</tt>
  #
  # <b>Options:</b>
  #
  # * <tt>:start</tt> - The start time for grabbing metrics. Default is 1 hour ago. Times will be converted to UTC.
  # * <tt>:end</tt> - The end time for grabbing metrics. Default is <tt>Time.now.utc</tt>. Times will be converted to UTC.
  # * <tt>:aggregate</tt> - Whether the metrics should be added together or an average across each metric should be returned.
  #   Default is false. Note that total is not necessary equal to the value on each server * num of servers. 
  #
  # <b>When to use <tt>:aggregate</tt>?</b>
  #
  # If you have a number of web servers, you may be interested in the total throughput for your application, not just the average 
  # on each server. For example:
  #
  # * Web Server No. 1 Average Throughput => 100 req/sec
  # * Web Server No. 2 Average Throughput => 150 req/sec
  #
  # <tt>:aggregate => true</tt> will return ~ 250 req/sec, giving the total throughput for your entire app. 
  # The default, <tt>:aggregate => false</tt>, will return ~ 125 req/sec, giving the average throughput across the web servers.
  #
  # <tt>:aggregate => true</tt> likely doesn't make sense for any metric that is on a 0-100 scale (like CPU Usage, Disk Capacity, etc.). 
  #
  # <b>Examples:</b>
  #
  #   # What is the average request time across my servers?
  #   Scout::Metric.average('request_time') => {:value => 0.20, :units => 'sec', :label => 'Request Time'}
  #
  #   # What is the average TOTAL throughput across my servers?
  #   Scout::Metric.average('request_rate', :aggregate => true)
  #
  #   # How much average memory did my servers use yesterday?
  #   # Scout::Metric.average('Memory Used', :start => Time.now-(24*60*60)*2, :end => Time.now-(24*60*60))
  #
  # @return [Hash]
  def self.average(id_or_name,options = {})
    calculate('AVG',id_or_name,options)
  end
  
  # Find the maximum value of a metric by ID or name (ex: 'last_minute').
  #
  # See +average+ for options and examples.
  #
  # @return [Hash]
  def self.maximum(id_or_name,options = {})
    calculate('MAX',id_or_name,options)
  end

  # Find the minimum value of a metric by ID or name (ex: 'last_minute').
  #
  # See +average+ for options and examples.
  #
  # @return [Hash]
  def self.minimum(id_or_name,options = {})
    calculate('MIN',id_or_name,options)
  end
  
  # Returns time series data.
  #
  # @return [Array]. This is a two-dimensional array, with the first element being the time in UTC and the second the value at that time.
  def self.to_array(function,id_or_name,options = {})
    start_time,end_time=format_times(options)
    consolidate,name,ids=series_options(id_or_name,options)
    
    response = Scout::Account.get("/descriptors/series.xml?name=#{CGI.escape(name.to_s)}&ids=#{ids}&function=#{function}&consolidate=#{consolidate}&plugin_ids=#{options[:plugin_ids]}&server_ids=#{options[:server_ids]}&group_ids=#{options[:group_ids]}&start=#{start_time}&end=#{end_time}")

    if response['records']
      response['records']
      response['records'].values.flatten.map { |r| [Time.parse(r['time']),r['value'].to_f] }
    else
      raise Scout::Error, response['error']
    end
  end
  
  # Generates a URL to a Google chart sparkline representation of the time series data.
  #
  # <b>Options:</b>
  #
  # * <tt>:size</tt> - The size of the image in pixels. Default is 200x30.
  # * <tt>:line_color</tt> - The color of the line. Default is 0077cc (blue).
  # * <tt>:line_width</tt> - The width of the line in pixels. Default is 2.
  #
  # @return [String]
  def self.to_sparkline(function,id_or_name,options = {})
    start_time,end_time=format_times(options)
    consolidate,name,ids=series_options(id_or_name,options)
    puts options.inspect
    puts start_time.inspect
    response = Scout::Account.get("/descriptors/sparkline?name=#{CGI.escape(name.to_s)}&ids=#{ids}&function=#{function}&consolidate=#{consolidate}&plugin_ids=#{options[:plugin_ids]}&server_ids=#{options[:server_ids]}&group_ids=#{options[:group_ids]}&start=#{start_time}&end=#{end_time}&size=#{options[:size]}&line_color=#{options[:line_color]}&line_width=#{options[:line_width]}")

    if response['error']
      raise Scout::Error, response['error']
    else
      response.body
    end
  end
  
  # See Scout::Metric#average for a list of options.
  #
  # @return [Hash]
  def average(opts = {})
    @avg_calc.options = opts
    @avg_calc
  end
  alias avg average

  # See Scout::Metric#average for a list of options.
  #
  # @return [Hash]
  def maximum(opts = {})
     @max_calc.options = opts
     @max_calc
  end
  alias max maximum

  # See Scout::Metric#average for a list of options.
  #
  # @return [Hash]
  def minimum(opts = {})
     @min_calc.options = opts
     @min_calc
  end
  alias min minimum
  
  # Metrics are identified by either their given ID or their name. If ID is present,
  # use it.
  def identifier #:nodoc:
    id? ? id : name
  end
  
  # Used to apply finder conditions
  def options_for_relationship(opts = {}) #:nodoc:
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

  protected
  
  def self.series_options(id_or_name,options) #:nodoc:
    consolidate = options[:aggregate] ? 'SUM' : 'AVG'
    
    if id_or_name.is_a?(Fixnum)
      name = nil
      ids = id_or_name
    else
      name = id_or_name
      ids = nil
    end
    
    return [consolidate,name,ids]
  end
  
  # The friendlier-named average, minimum, and maximum methods call this method.
  def self.calculate(function,id_or_name,options = {}) #:nodoc:
    start_time,end_time=format_times(options)
    consolidate = options[:aggregate] ? 'SUM' : 'AVG'
    
    if id_or_name.is_a?(Fixnum)
      name = nil
      ids = id_or_name
    else
      name = id_or_name
      ids = nil
    end
    
    response = Scout::Account.get("/data/value?name=#{CGI.escape(name.to_s)}&ids=#{ids}&function=#{function}&consolidate=#{consolidate}&plugin_ids=#{options[:plugin_ids]}&server_ids=#{options[:server_ids]}&group_ids=#{options[:group_ids]}&start=#{start_time}&end=#{end_time}")

    if response['data']
      response['data']
    else
      raise Scout::Error, response['error']
    end
  end
  
   # API expects times in epoch.
   def self.format_times(options)
     options.values_at(:start,:end).map { |t| t ? t.to_i : nil }
   end
  
end