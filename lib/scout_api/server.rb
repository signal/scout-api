class Scout::Server < Hashie::Mash
  # Retrieve metric information. See Scout::Metric#average for a list of options for the calculation
  # methods (average, minimum, maximum).
  # 
  # Examples:
  # 
  # * <tt>Scout::Server.metrics => All metrics associated with this server.</tt>
  # * <tt>Scout::Server.metrics.all(:name => 'Memory Used') => Metrics with name =~ 'Memory Used' on this server.</tt>
  # * <tt>Scout::Server.metrics.average(:name => 'Memory Used') => Average value of metrics with name =~ 'Memory Used' on this server.</tt> 
  # * <tt>Scout::Server.metrics.maximum(:name => 'Memory Used')</tt>
  # * <tt>Scout::Server.metrics.minimum(:name => 'Memory Used')</tt>
  # * <tt>Scout::Server.metrics.average(:name => 'request_rate', :aggregate => true) => Sum metrics, then take average</tt>
  # * <tt>Scout::Server.metrics.average(:name => 'request_rate', :start => Time.now.utc-5*3600, :end => Time.now.utc-2*3600) => Retrieve data starting @ 5 hours ago ending at 2 hours ago</tt>
  # * <tt>Scout::Server.metrics.average(:name => 'Memory Used').to_array => An array of time series values over the past hour.</tt> 
  # * <tt>Scout::Server.metrics.average(:name => 'Memory Used').to_sparkline => A Url to a Google Sparkline Chart.</tt>
  attr_reader :metrics
  
  def initialize(hash) #:nodoc:
    if hash['active_alerts']
      @alert_hash = hash['active_alerts']
      hash.delete('active_alerts')
    end
    @metrics = Scout::MetricProxy.new(self)
    super(hash)
  end
  
  # Ruby 1.9.2 Hash#key is a method. This overrides so +key+ returns Server#key.
  def key #:nodoc:
    self[:key]
  end

  # Finds the first server that meets the given conditions. Possible parameter formats:
  # 
  # * <tt>Scout::Server.first</tt>
  # * <tt>Scout::Server.first(1)</tt>
  # * <tt>Scout::Server.first(:name => 'db slaves')</tt>
  # * <tt>Scout::Server.first(:host => 'web*.geocities')</tt>
  #
  #
  # For the <tt>:name</tt> and <tt>:host</tt> options, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  # 
  # @return [Scout::Server]
  def self.first(id_or_options = nil)
    if id_or_options.nil?
      response = Scout::Account.get("/clients.xml?limit=1")
      Scout::Server.new(response['clients'].first)
    elsif id_or_options.is_a?(Hash)
      if name=id_or_options[:name]
        response = Scout::Account.get("/clients.xml?name=#{CGI.escape(name)}")
        raise Scout::Error, 'Not Found' if response['clients'].nil?
        Scout::Server.new(response['clients'].first)
      elsif host=id_or_options[:host]
        response = Scout::Account.get("/clients.xml?host=#{CGI.escape(host)}")
        raise Scout::Error, 'Not Found' if response['clients'].nil?
        Scout::Server.new(response['clients'].first)
      else
        raise Scout::Error, "Invalid finder condition"
      end
    elsif id_or_options.is_a?(Fixnum)
      response = Scout::Account.get("/clients/#{id_or_options}.xml")
      Scout::Server.new(response['client'])
    elsif id_or_options.is_a?(String)
      warn "Server#first(hostname) will be deprecated. Use Server#first(:host => hostname)"
      response = Scout::Account.get("/clients.xml?host=#{CGI.escape(id_or_options)}")
      raise Scout::Error, 'Not Found' if response['clients'].nil?
      Scout::Server.new(response['clients'].first)
    else
      raise Scout::Error, "Invalid finder condition"
    end
  end
  
  # Finds all servers that meets the given conditions. Possible parameter formats:
  # 
  # * <tt>Scout::Server.all(:name => 'db slaves')</tt>
  # * <tt>Scout::Server.all(:host => 'web*.geocities')</tt>
  #
  # For the <tt>:name</tt> and <tt>:host</tt> options, a {MySQL-formatted Regex}[http://dev.mysql.com/doc/refman/5.0/en/regexp.html] can be used.
  # 
  # @return [Array] An array of Scout::Server objects
  def self.all(options = {})
    if name=options[:name]
      response = Scout::Account.get("/clients.xml?name=#{CGI.escape(name)}")
    elsif host=options[:host]
      response = Scout::Account.get("/clients.xml?host=#{CGI.escape(host)}")
    elsif options.empty?
      response = Scout::Account.get("/clients.xml")
    else
      raise Scout::Error, "Invalid finder condition"
    end
    response['clients'] ? response['clients'].map { |client| Scout::Server.new(client) } : Array.new
  end
  
  # Creates a new server. If an error occurs, a [Scout::Error] is raised.
  #
  # An optional existing server id can be used as a template:
  # <tt>Scout::Server.create('web server 12',:id => 99999)</tt>
  #
  # @return [Scout::Server]
  def self.create(name,options = {})
    id = options[:id]
    response = Scout::Account.post("/#{Scout::Account.param}/clients.xml", 
    :query => {:client => {:name => name, :copy_plugins_from_client_id => id}, :api_version => Scout::VERSION})
    
    raise Scout::Error, response['errors']['error'] if response['errors']
    
    first(response.headers['id'].first.to_i)
  end
  
  # Delete a server by <tt>id</tt>. If an error occurs, a [Scout::Error] is raised.
  #
  # @return [true]
  def self.delete(id)
    response = Scout::Account.delete("/#{Scout::Account.param}/clients/#{id}.xml?api_version=#{Scout::VERSION}")

    if response.headers['status'].first.match('404')
      raise Scout::Error, "Server Not Found"
    elsif !response.headers['status'].first.match('200')
      raise Scout::Error, "An error occured"
    else
      return true
    end
  end

  # Active alerts for this server
  #
  # @return [Array] An array of Scout::Alert objects
  def active_alerts
    @active_alerts ||= @alert_hash.map { |a| decorate_with_server(Scout::Alert.new(a)) }
  end

  # Recent alerts for this server
  #
  # @return [Array] An array of Scout::Alert objects
  def alerts
    response = Scout::Account.get("/clients/#{self.id}/activities.xml")
    response['alerts'].map { |alert| decorate_with_server(Scout::Alert.new(alert)) }
  end

  # Details about all plugins for this server
  #
  # @return [Array] An array of Scout::Plugin objects
  def plugins
    response = Scout::Account.get("/clients/#{self.id}/plugins.xml")
    response['plugins'].map { |plugin| decorate_with_server(Scout::Plugin.new(plugin)) }
  end

  # Details about a specific plugin
  #
  # @return [Scout::Plugin]
  def plugin(id)
    response = Scout::Account.get("/clients/#{self.id}/plugins/#{id}.xml")
    decorate_with_server(Scout::Plugin.new(response['plugin']))
  end

  # Details about all triggers for this server
  #
  # @return [Array] An array of Scout::Trigger objects
  def triggers
    response = Scout::Account.get("/clients/#{self.id}/triggers.xml")
    response['triggers'].map { |trigger| decorate_with_server(Scout::Trigger.new(trigger)) }
  end

protected

  def decorate_with_server(hashie) #:nodoc:
    hashie.server = self
    hashie
  end

end