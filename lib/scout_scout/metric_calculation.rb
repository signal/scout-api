class ScoutScout::MetricCalculation
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$|proxy_|^object_id$)/ }
  attr_accessor :args
  def initialize(owner,function) #:nodoc:
    @owner = owner
    @function = function
  end
  
  def to_sparkline
    puts "sparkline!!!! args: #{@args.inspect}"
    metric_name = @args.first
    options = {}
    if @args.size == 2
      options.merge!(@args.last)
    end
    options.merge!(owner_key_value)
    ScoutScout::Metric.to_sparkline(
      @function,metric_name,options
    )
  end
  
  def to_array 
    puts "to_array"
    metric_name = @args.first
    options = {}
    if @args.size == 2
      options.merge!(@args.last)
    end
    options.merge!(owner_key_value)
    ScoutScout::Metric.to_array(
      @function,metric_name,options
    )
  end
  
  
  def load_target #:nodoc:
    @target = find_target
    @target
  end
  
  # next:
  # * @args.last should be options. make default {}
  # * 
  def find_target #:nodoc:
    puts "finding target function: #{@function} args: #{@args.inspect}"
    metric_name = @args.first
    options = {}
    if @args.size == 2
      options.merge!(@args.last)
    end
    options.merge!(owner_key_value)
    ScoutScout::Metric.calculate(
      @function,metric_name,options
    )
  end
  
  private
  
  def owner_key_value
   { (@owner.owner.class.to_s.sub('ScoutScout::','').downcase+'_ids').to_sym => @owner.owner.id}
  end
  
  def method_missing(method, *args)
    puts "method missing!!!! #{method.to_s} args: #{args.inspect}"
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