class ScoutScout::Group < Hashie::Mash
  attr_reader :metrics

  def initialize(hash)
    @metrics = MetricProxy.new(self)
    super(hash)
  end
  
  # Finds a single group that meets the given conditions. Possible parameter formats:
  # 
  # ScoutScout::Group.first(1) => Finds the group with ID=1
  # ScoutScout::Group.first(:name => 'db slaves') => Finds the first group where name=~'db slaves'
  #
  # Use a MySQL-formatted Regex. http://dev.mysql.com/doc/refman/5.0/en/regexp.html
  #
  # @return [ScoutScout::Group]
  def self.first(id_or_options)
    if id_or_options.is_a?(Hash)
      if name=id_or_options[:name]
        response = ScoutScout.get("/#{ScoutScout.account}/groups.xml?name=#{CGI.escape(name)}")
        raise ScoutScout::Error, 'Not Found' if response['groups'].nil?
        ScoutScout::Server.new(response['groups'].first)
      else
        raise ScoutScout::Error, "Invalid finder condition"
      end
    elsif id_or_options.is_a?(Fixnum)
      response = ScoutScout.get("/#{ScoutScout.account}/groups/#{id_or_options}.xml")
      ScoutScout::Group.new(response['group'])
    else
      raise ScoutScout::Error, "Invalid finder condition"
    end
  end
  
  # Finds all groups that meets the given conditions. Possible parameter formats:
  # 
  # ScoutScout::Group.all => Returns all groups
  # ScoutScout::Group.all(:name => 'web') => Finds groups where name=~'web'
  #
  # Use a MySQL-formatted Regex. http://dev.mysql.com/doc/refman/5.0/en/regexp.html
  #
  # @return [Array] An array of ScoutScout::Group objects
  def self.all(options = {})
    if name=options[:name]
      response = ScoutScout.get("/#{ScoutScout.account}/groups.xml?name=#{name}")
    elsif options.empty?
      response = ScoutScout.get("/#{ScoutScout.account}/groups.xml")
    else
      raise ScoutScout::Error, "Invalid finder condition"
    end
    response['groups'] ? response['groups'].map { |g| ScoutScout::Group.new(g) } : Array.new
  end
  
end