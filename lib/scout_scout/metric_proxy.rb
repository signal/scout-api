# This class works similar to Ruby on Rails' AssociationProxy, providing a nice interface to metrics
# from owner objects in Scout (ex: Server, Group, Plugin).
# See http://stackoverflow.com/questions/1529606/how-do-rails-association-methods-work for background
# 
# Example usage:
# group.metrics => all metrics associated with the group
# server.metrics.average('idle') => average value of all metrics w/name 'idle' associated with the server
class ScoutScout::MetricProxy
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }
  
  def initialize(owner) #:nodoc:
    @owner = owner
    @loaded = false
  end
  
  # Find all metrics w/name <tt>metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # Example:
  #
  # <tt>server.metrics.all('request_rate')</tt> => returns all metrics on +server+ w/the name 'request_rate'.
  #
  # @return [Array] An array of [ScoutScout::Metric] objects
  def all(metric_name = nil)
    ScoutScout::Metric.all(
      owner_key_value.merge!(:name => metric_name)
    )
  end
  
  # Calculate the average value of <tt>metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # See Metric#average for options.
  #
  # @return [Hash]
  def average(metric_name,options = {})
    options.merge!(owner_key_value)
    ScoutScout::Metric.average(
      metric_name,
      options
    )
  end
  alias avg average
  
  # Calculate the minimum value of <tt>metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # See Metric#average for options.
  #
  # @return [Hash]
  def minimum(metric_name,options = {})
    options.merge!(owner_key_value)
    ScoutScout::Metric.minimum(
      metric_name,
      options
    )
  end
  alias min minimum
  
  # Calculate the maximum value of <tt>metric_name</tt> associated with the proxy owner (Group, Server, or Plugin).
  #
  # See Metric#average for options.
  #
  # @return [Hash]
  def maximum(metric_name,options = {})
    options.merge!(owner_key_value)
    ScoutScout::Metric.maximum(
      metric_name,
      options
    )
  end
  alias max maximum
  
  def load_target #:nodoc:
    return nil unless defined?(@loaded)

    if !loaded?
      @target = find_target
    end

    @loaded = true
    @target
  end
  
  def loaded? #:nodoc:
    @loaded
  end
  
  def find_target #:nodoc:
    if @owner.is_a?(ScoutScout::Plugin) # plugin already has metric info
      @owner.descriptor_hash.map { |d| ScoutScout::Metric.new(d) }
    else
      ScoutScout::Metric.all(owner_key_value)
    end
  end
  
  private
  
  def owner_key_value
   { (@owner.class.to_s.sub('ScoutScout::','').downcase+'_ids').to_sym => @owner.id}
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