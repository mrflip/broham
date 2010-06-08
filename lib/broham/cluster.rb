#
#
# This actually reaches into the settings hash and supplies
#
# (it's written like this so that chef
#
class BrohamNode < RightAws::ActiveSdb::Base
  attr_accessor :settings

  def self.set_cluster_info! settings
    node = new(settings)
    node.set_cluster_info!
    node.settings
  end

  #
  # Settings hash must contain
  # * 'aws'::          a hash with keys 'access_key' and 'secret_access_key' holding your AWS credentsials
  # * 'cluster_name':: name of the cluster
  # * 'cluster_role':: role within that cluster
  #
  # Method will set values for
  # * 'cluster_role_index'
  # * 'node_name'
  #
  def initialize settings
    self.settings = settings
  end

  def set_cluster_info!
    settings['cluster_role_index'] ||= broham_attr('idx')
  end

  # retrieve a simple scalar value from the broham info
  def broham_attr attr
    [ broham_info[attr] ].flatten.first
  end

  # Return cached copy of the broham registration, if any
  #
  def broham_info
    return @broham_info if @broham_info
    establish_connection
    @broham_info ||= Broham.register_as_next("#{settings["cluster_name"]}-#{settings["cluster_role"]}")
  end

  def establish_connection
    raise "Need to supply an AWS credentials hash with keys 'access_key' and 'secret_access_key'" if settings["aws"].blank?
    Broham.establish_connection(:access_key => settings["aws"]["access_key"], :secret_access_key => settings["aws"]["secret_access_key"])
  end
end
