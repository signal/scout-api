class Scout::Plugin < Hashie::Mash
  attr_accessor :server
  
  # Retrieve metric information. See {Scout::Metric.average} for a list of options for the calculation
  # methods (average, minimum, maximum).
  # 
  # Examples:
  # 
  #  # All metrics associated with this plugin.
  #  Scout::Plugin.metrics
  #
  #  # Metrics with name =~ 'Memory Used' on this plugin.
  #  Scout::Plugin.metrics.all(:name => 'Memory Used')
  #
  #  # Average value of metrics with name =~ 'Memory Used' on this plugin.
  #  Scout::Plugin.metrics.average(:name => 'Memory Used')
  #
  #  # Maximum value...
  #  Scout::Plugin.metrics.maximum(:name => 'Memory Used')
  #
  #  # Minumum value...
  #  Scout::Plugin.metrics.minimum(:name => 'Memory Used')
  #
  #  # Sum metrics, then take average
  #  Scout::Plugin.metrics.average(:name => 'request_rate', :aggregate => true)
  #
  #  # Retrieve data starting @ 5 hours ago ending at 2 hours ago
  #  Scout::Plugin.metrics.average(:name => 'request_rate', :start => Time.now.utc-5*3600, :end => Time.now.utc-2*3600)
  #
  #  # An array of time series values over the past hour
  #  Scout::Plugin.metrics.average(:name => 'Memory Used').to_array
  #
  #  # A Url to a Google Sparkline Chart.
  #  Scout::Plugin.metrics.average(:name => 'Memory Used').to_sparkline
  attr_reader :metrics
  
  attr_reader :descriptor_hash #:nodoc:

  def initialize(hash) #:nodoc:
    if hash['descriptors'] && hash['descriptors']['descriptor']
      @descriptor_hash = hash['descriptors']['descriptor']
      hash.delete('descriptors')
    end
    @metrics = Scout::MetricProxy.new(self)
    super(hash)
  end

  def email_subscribers
    response = Scout::Account.get("/clients/#{server.id}/email_subscribers?plugin_id=#{id}")
    doc = Nokogiri::HTML(response.body)

    table = doc.css('table.list').first
    user_rows = table.css('tr')[1..-1] # skip first row, which is headings

    user_rows.map do |row|
      name_td, receiving_notifications_td = *row.css('td')

      name = name_td.content.gsub(/[\t\n]/, '')
      checked = receiving_notifications_td.css('input').attribute('checked')
      receiving_notifications = checked && checked.value == 'checked'
      Hashie::Mash.new :name => name, :receiving_notifications => receiving_notifications
    end
  end

  def triggers
    response = Scout::Account.get("/clients/#{server.id}/triggers.xml?plugin_id=#{id}")
    response['triggers'].map { |trigger| decorate_with_server_and_plugin(Scout::Trigger.new(trigger)) }
  end

protected

  def decorate_with_server_and_plugin(hashie) #:nodoc:
    hashie.server = self.server
    hashie.plugin = self
    hashie
  end

end
