class Scout::Account
  include HTTParty
  base_uri 'https://scoutapp.com'
  #base_uri 'http://localhost:3000'
  
  format :xml
  mattr_inheritable :param

  def initialize(account_param, username, password)
    self.class.param = account_param
    self.class.basic_auth username, password
  end

  # Recent alerts across all servers on this account
  #
  # @return [Array] An array of Scout::Alert objects
  def alerts
    response = self.class.get("/activities.xml")
    response['alerts'] ? response['alerts'].map { |alert| Scout::Alert.new(alert) } : Array.new
  end

  def people
    response = self.class.get("/account_memberships")
    doc = Nokogiri::HTML(response.body)

    tables = doc.css('table.list')
    # first table is pending
    # second is active
    active_table = tables.last
    user_rows = active_table.css('tr')[1..-1] # skip first row, which is headings

    user_rows.map do |row|
      name_td, email_td, admin_td, links_td = *row.css('td')

      name = name_td.content.gsub(/[\t\n]/, '')
      email = email_td.content.gsub(/[\t\n]/, '')
      admin = admin_td.content.gsub(/[\t\n]/, '') == 'Yes'
      id = if links_td.inner_html =~ %r{/#{self.class.param}/account_memberships/(\d+)}
             $1.to_i
           end

      Scout::Person.new :id => id, :name => name, :email => email, :admin => admin
    end

  end
  
  class << self
    alias_method :http_get, :get
  end
  
  # Checks for errors via the HTTP status code. If an error is found, a 
  # Scout::Error is raised. Otherwise, the response.
  # 
  # @return HTTParty::Response
  def self.get(uri)
    raise Scout::Error, 
          "Authentication is required (scout = Scout::Account.new('youraccountname', 'your@awesome.com', 'sekret'))" if param.nil?
    uri = "/#{param}" + uri + (uri.include?('?') ? '&' : '?') + "api_version=#{Scout::VERSION}"
    #puts "GET: #{uri}"
    response = http_get(uri)
    response.code.to_s =~ /^(4|5)/ ? raise( Scout::Error,response.message) : response
  end
end