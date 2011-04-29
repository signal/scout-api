class ScoutScout::Server < Hashie::Mash
  # Retrieve metric information. See ScoutScout::Metric#average for a list of options for the calculation
  # methods (average, minimum, maximum).
  # 
  # Examples:
  # 
  # * <tt>ScoutScout::Server.metrics => All metrics associated with this server.</tt>
  # * <tt>ScoutScout::Server.metrics.all(:name => 'mem_used') => Metrics with name =~ 'mem_used' on this server.</tt>
  # * <tt>ScoutScout::Server.metrics.average(:name => 'mem_used') => Average value of metrics with name =~ 'mem_used' on this server.</tt> 
  # * <tt>ScoutScout::Server.metrics.maximum(:name => 'mem_used')</tt>
  # * <tt>ScoutScout::Server.metrics.minimum(:name => 'mem_used')</tt>
  # * <tt>ScoutScout::Server.metrics.average(:name => 'request_rate', :aggregate => true) => Sum metrics, then take average</tt>
  # * <tt>ScoutScout::Server.metrics.average(:name => 'request_rate', :start => Time.now.utc-5*3600, :end => Time.now.utc-2*3600) => Retrieve data starting @ 5 hours ago ending at 2 hours ago</tt>
  attr_reader :metrics
  
  def initialize(hash) #:nodoc:
    if hash['active_alerts']
      @alert_hash = hash['active_alerts']
      hash.delete('active_alerts')
    end
    @metrics = ScoutScout::MetricProxy.new(self)
    super(hash)
  end

  # Finds the first server that meets the given conditions. Possible parameter formats:
  # 
  # * <tt>ScoutScout::Server.first(1)</tt>
  # * <tt>ScoutScout::Server.first(:name => 'db slaves')</tt>
  # * <tt>ScoutScout::Server.first(:host => 'web*.geocities')</tt>
  #
  #
  # For the <tt>:name</tt> and <tt>:host</tt> options, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  # 
  # @return [ScoutScout::Server]
  def self.first(id_or_options)
    if id_or_options.is_a?(Hash)
      if name=id_or_options[:name]
        response = ScoutScout.get("/#{ScoutScout.account}/clients.xml?name=#{name}")
        raise ScoutScout::Error, 'Not Found' if response['clients'].nil?
        ScoutScout::Server.new(response['clients'].first)
      elsif host=id_or_options[:host]
        response = ScoutScout.get("/#{ScoutScout.account}/clients.xml?host=#{host}")
        raise ScoutScout::Error, 'Not Found' if response['clients'].nil?
        ScoutScout::Server.new(response['clients'].first)
      else
        raise ScoutScout::Error, "Invalid finder condition"
      end
    elsif id_or_options.is_a?(Fixnum)
      response = ScoutScout.get("/#{ScoutScout.account}/clients/#{id_or_options}.xml")
      ScoutScout::Server.new(response['client'])
    elsif id_or_options.is_a?(String)
      warn "Server#first(hostname) will be deprecated. Use Server#first(:host => hostname)"
      response = ScoutScout.get("/#{ScoutScout.account}/clients.xml?host=#{id_or_options}")
      raise ScoutScout::Error, 'Not Found' if response['clients'].nil?
      ScoutScout::Server.new(response['clients'].first)
    else
      raise ScoutScout::Error, "Invalid finder condition"
    end
  end
  
  # Finds all servers that meets the given conditions. Possible parameter formats:
  # 
  # * <tt>ScoutScout::Server.all(:name => 'db slaves')</tt>
  # * <tt>ScoutScout::Server.all(:host => 'web*.geocities')</tt>
  #
  # For the <tt>:name</tt> and <tt>:host</tt> options, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  # 
  # @return [Array] An array of ScoutScout::Server objects
  def self.all(options = {})
    if name=options[:name]
      response = ScoutScout.get("/#{ScoutScout.account}/clients.xml?name=#{name}")
    elsif host=options[:host]
      response = ScoutScout.get("/#{ScoutScout.account}/clients.xml?host=#{host}")
    elsif options.empty?
      response = ScoutScout.get("/#{ScoutScout.account}/clients.xml")
    else
      raise ScoutScout::Error, "Invalid finder condition"
    end
    response['clients'] ? response['clients'].map { |client| ScoutScout::Server.new(client) } : Array.new
  end
  
  # Creates a new server. If an error occurs, a [ScoutScout::Error] is raised.
  #
  # An optional existing server id can be used as a template:
  # <tt>ScoutScout::Server.create('web server 12',:id => 99999)</tt>
  #
  # @return [ScoutScout::Server]
  def self.create(name,options = {})
    id = options[:id]
    response = ScoutScout.post("/#{ScoutScout.account}/clients.xml", 
    :query => {:client => {:name => name, :copy_plugins_from_client_id => id}})
    
    raise ScoutScout::Error, response['errors']['error'] if response['errors']
    
    first(response.headers['id'].first.to_i)
  end
  
  # Delete a server by <tt>id</tt>. If an error occurs, a [ScoutScout::Error] is raised.
  #
  # @return [true]
  def self.delete(id)
    response = ScoutScout.delete("/#{ScoutScout.account}/clients/#{id}.xml")

    if response.headers['status'].first.match('404')
      raise ScoutScout::Error, "Server Not Found"
    elsif !response.headers['status'].first.match('200')
      raise ScoutScout::Error, "An error occured"
    else
      return true
    end
  end

  # Active alerts for this server
  #
  # @return [Array] An array of ScoutScout::Alert objects
  def active_alerts
    @active_alerts ||= @alert_hash.map { |a| decorate_with_server(ScoutScout::Alert.new(a)) }
  end

  # Recent alerts for this server
  #
  # @return [Array] An array of ScoutScout::Alert objects
  def alerts
    response = ScoutScout.get("/#{ScoutScout.account}/clients/#{self.id}/activities.xml")
    response['alerts'].map { |alert| decorate_with_server(ScoutScout::Alert.new(alert)) }
  end

  # Details about all plugins for this server
  #
  # @return [Array] An array of ScoutScout::Plugin objects
  def plugins
    response = ScoutScout.get("/#{ScoutScout.account}/clients/#{self.id}/plugins.xml")
    response['plugins'].map { |plugin| decorate_with_server(ScoutScout::Plugin.new(plugin)) }
  end

  # Details about a specific plugin
  #
  # @return [ScoutScout::Plugin]
  def plugin(id)
    response = ScoutScout.get("/#{ScoutScout.account}/clients/#{self.id}/plugins/#{id}.xml")
    decorate_with_server(ScoutScout::Plugin.new(response['plugin']))
  end

  # Details about all triggers for this server
  #
  # @return [Array] An array of ScoutScout::Trigger objects
  def triggers
    response = ScoutScout.get("/#{ScoutScout.account}/clients/#{self.id}/triggers.xml")
    response['triggers'].map { |trigger| decorate_with_server(ScoutScout::Trigger.new(trigger)) }
  end

protected

  def decorate_with_server(hashie) #:nodoc:
    hashie.server = self
    hashie
  end

end