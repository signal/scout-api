class Scout::Alert < Hashie::Mash
  attr_writer :server

  # The Scout server that generated this alert
  #
  # @return [Scout::Server]
  def server
    @server ||= Scout::Server.first(client_id)
  end

  # The Scout plugin that generated this alert
  #
  # @return [Scout::Plugin]
  def plugin
    server.plugin(plugin_id)
  end
end