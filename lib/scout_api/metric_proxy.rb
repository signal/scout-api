# This class works similar to Ruby on Rails' AssociationProxy, providing a nice interface to metrics
# from owner objects in Scout (ex: Server, Group, Plugin).
# See http://stackoverflow.com/questions/1529606/how-do-rails-association-methods-work for background
# 
# Example usage:
# group.metrics => all metrics associated with the group
# server.metrics.average('idle') => average value of all metrics w/name 'idle' associated with the server
class Scout::MetricProxy
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$|is\_a\?)/ }
  attr_reader :owner
  
  def initialize(owner) #:nodoc:
    @owner = owner
    @avg_calc = Scout::MetricCalculation.new(self,:AVG)
    @min_calc = Scout::MetricCalculation.new(self,:MIN)
    @max_calc = Scout::MetricCalculation.new(self,:MAX)
  end
  
  # Calculate the average value of the metric w/<tt>:name => metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # See Metric#average for options.
  #
  # @return [Hash]
  def average(options)
    @avg_calc.metric_name = metric_from_options(options)
    @avg_calc.options = options
    @avg_calc
  end
  alias avg average
  
  # Calculate the minimum value of the metric w/<tt>:name => metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # See Metric#average for options.
  #
  # @return [Hash]
  def minimum(options)
    @min_calc.metric_name = metric_from_options(options)
    @min_calc.options = options    
    @min_calc
  end
  alias min minimum
  
  # Calculate the maximum value of the metric w/<tt>:name => metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # See Metric#average for options.
  #
  # @return [Hash]
  def maximum(options)
    @max_calc.metric_name = metric_from_options(options)
    @max_calc.options = options    
    @max_calc
  end
  alias max maximum
  
  # Find all metrics w/ <tt>:name => metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # Example:
  #
  # <tt>server.metrics.all(:name => 'request_rate')</tt> => returns all metrics on +server+ w/the name 'request_rate'.
  #
  # @return [Array] An array of [Scout::Metric] objects
  def all(options = nil)
    metric_name = options[:name] if options
    Scout::Metric.all(
      owner_key_value.merge!(:name => metric_name)
    )
  end
  
  def load_target #:nodoc:
    @target = find_target
  end
  
  def find_target #:nodoc:
    if @owner.is_a?(Scout::Plugin) # plugin already has metric info
      @owner.descriptor_hash.map { |d| Scout::Metric.new(d) }
    else
      Scout::Metric.all(owner_key_value)
    end
  end
  
  private
  
  # Ensures that a metric name is provided in the +options+ Hash. 
  # If one isn't provided, a Scout::Error is raised.
  #
  # @return [String]
  def metric_from_options(options)
    metric_name = options[:name]
    raise Scout::Error, "The name of the metric is required (:name => metric_name)" if metric_name.blank?
    metric_name
  end
  
  def owner_key_value
   { (@owner.class.to_s.sub('Scout::','').downcase+'_ids').to_sym => @owner.id}
  end
  
  def method_missing(method, *args)
    if load_target
      unless @target.respond_to?(method)
        message = "undefined method `#{method.to_s}' for \"#{@target}\":#{@target.class.to_s}"
        raise NoMethodError, message
      end

      if block_given?
        @target.send(method, *args)  { |*block_args| yield(*block_args) }
      else
        @target.send(method, *args)
      end
    end
  end
  
end