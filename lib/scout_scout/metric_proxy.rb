# This class works similar to Ruby on Rails' AssociationProxy, providing a nice interface to metrics
# from owner objects in Scout (ex: Server, Group, Plugin).
# See http://stackoverflow.com/questions/1529606/how-do-rails-association-methods-work for background
# 
# Example usage:
# group.metrics => all metrics associated with the group
# server.metrics.average('idle') => average value of all metrics w/name 'idle' associated with the server
class MetricProxy
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }
  
  def initialize(owner)
    @owner = owner
    @loaded = false
  end
  
  # Find all metrics w/name +metric_name+ associated with the proxy owner (Group, Server, or Plugin).
  #
  # Example:
  # server.metrics.all('request_rate') => returns all metrics on +server+ w/the name 'request_rate'.
  #
  # @return [Array] An array of ScoutScout::Metric objects
  def all(metric_name,options = {})
    options.merge!(:name => metric_name).merge!(owner_key_value)
    ScoutScout::Metric.all(
      metric_name,
      options
    )
  end
  
  # Calculate the average value of +metric_name+ associated with the proxy owner (Group, Server, or Plugin).
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
  
  # Calculate the minimum value of +metric_name+ associated with the proxy owner (Group, Server, or Plugin).
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
  
  # Calculate the maximum value of +metric_name+ associated with the proxy owner (Group, Server, or Plugin).
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
  
  def load_target
    return nil unless defined?(@loaded)

    if !loaded?
      @target = find_target
    end

    @loaded = true
    @target
  end
  
  def loaded?
    @loaded
  end
  
  def find_target
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