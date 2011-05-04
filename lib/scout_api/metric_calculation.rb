class Scout::MetricCalculation
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }
  attr_accessor :metric_name, :options
  
  def initialize(owner,function) #:nodoc:
    @owner = owner
    @function = function
    @options = {}
  end
  
  def to_sparkline(opts = {})
    options.merge!(opts).merge!(owner_key_value)
    Scout::Metric.to_sparkline(
      @function,metric_name,options
    )
  end
  
  def to_array 
    options.merge!(owner_key_value)
    Scout::Metric.to_array(
      @function,metric_name,options
    )
  end
  alias to_a to_array
  
  def load_target #:nodoc:
    @target = find_target
  end
  
  def find_target #:nodoc:
    options.merge!(owner_key_value)
    Scout::Metric.calculate(
      @function,metric_name,options
    )
  end
  
  private
  
  def owner_key_value
    if @owner.is_a?(Scout::Metric)
      @owner.options_for_relationship
    else
      { (@owner.owner.class.to_s.sub('Scout::','').downcase+'_ids').to_sym => @owner.owner.id}
    end
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