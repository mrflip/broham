# SimpleDB interface
require 'right_aws'
require 'sdb/active_sdb'
require 'broham/sdb'
require 'broham/cluster'
require 'set'

# Machine information
require 'ohai'
OHAI_INFO = Ohai::System.new unless defined?(OHAI_INFO)
OHAI_INFO.all_plugins
# Settings from Configliere.
require 'configliere'
Settings.define :access_key,        :required => true, :description => "Amazon AWS access key ID     -- found in your AWS console (http://bit.ly/awsconsole)", :broham => true
Settings.define :secret_access_key, :required => true, :description => "Amazon AWS secret access key -- found in your AWS console (http://bit.ly/awsconsole)", :broham => true

::Log = Logger.new(STDERR) unless defined?(Log)

#
# Make sure you are using a recent (>= 1.11,0) version of right_aws, and set the
# SDB_API_VERSION environment variable to '2009-04-15':
#   export SDB_API_VERSION='2009-04-15'
#

#
# Broham expects a hash constant +Settings+ with values for +:secret_access_key+
# and +:access_key+. The configliere gem (http://github.com/mrflip/configliere)
# can help with that.
#
class Broham < RightAws::ActiveSdb::Base
  # Returns the last-registered host in the given role
  def self.latest role
    select_by_role(role, :order => 'timestamp DESC')
  end

  # Returns all hosts in the given role
  def self.list_like role
    select(:all, :order => 'timestamp DESC').select{|bro| bro[:role].to_s =~ /^#{role}/ }
  end

  #
  def self.roles name=nil
    name ||= my_default_ip
    select_all_by_name(name)
  end
  # s
  def self.entry_for_role role, name=nil
    name ||= my_default_ip
    select_by_role_and_name(role, name) || new(:name => name, :role => role)
  end

  def self.register role, name=nil, extra_attrs={}
    establish_connection
    bro = entry_for_role(role, name)
    bro.attributes = bro.attributes.merge(host_attrs.merge(extra_attrs))
    bro.save
    role_idxs!(role)
    bro
  end

  #
  # Removes all registrations for the given role wildcard
  #
  def self.unregister_like role
    hosts_like(role).each(&:unregister)
  end
  #
  def self.unregister role, name
    host(role).each(&:unregister)
  end
  def unregister
    delete
  end

  #
  # alternative interface
  #

  # alternative syntax for #register
  def self.yo!(*args)           register *args        ; end
  # alternative syntax for #host
  def self.sup?(*args)          host *args            ; end
  # alternative syntax for #hosts_like
  def self.sup_yall?(*args)     hosts_like *args      ; end
  # alternative syntax for #unregister
  def self.diss(*args)          unregister *args      ; end
  # alternative syntax for #unregister_like
  def self.fuck_all_yall(*args) unregister_like *args ; end

  #
  # Do an ok job of consistently assigning indices.
  #
  # * nodes with an idx retain that idx.
  # * nodes without an idx acquire the lowest unassigned idx,
  #   with lowest timestamp choosing first
  #
  # this isn't perfectly consistent, but isn't terrible.
  #
  def self.role_idxs! role
    bros = select_all_by_role(role, :order => 'timestamp ASC')
    avail_idxes = (0 .. bros.length).to_set
    need_idxes  = []
    indexed     = {}
    bros.each do |bro|
      if bro.idx
        indexed[bro.idx] = bro.id
        avail_idxes.delete(bro.idx)
      else
        need_idxes << bro
      end
    end
    need_idxes.zip(avail_idxes.sort).each do |bro,idx|
      indexed[idx] = bro.id
      bro['idx']   = idx
      bro.save
    end
    indexed.invert
  end

  #
  # Registration attributes
  #

  def self.host_attrs
    { :timestamp => timestamp, :private_ip => my_private_ip, :public_ip => my_public_ip, :default_ip => my_default_ip, :fqdn => my_fqdn  }.to_mash
  end

  def self.my_private_ip()        OHAI_INFO[:cloud][:private_ips].first rescue nil ; end
  def self.my_public_ip()         OHAI_INFO[:cloud][:public_ips].first  rescue nil ; end
  def self.my_default_ip()        OHAI_INFO[:ipaddress]                            ; end
  def self.my_fqdn()              OHAI_INFO[:fqdn]                                 ; end
  def self.my_availability_zone() OHAI_INFO[:ec2][:availability_zone]              ; end
  def self.timestamp()            Time.now.utc.strftime("%Y%m%d%H%M%SZ")            ; end

  def private_ip()        self['private_ip'       ].first || default_ip ; end
  def public_ip()         self['public_ip'        ].first || default_ip ; end
  def default_ip()        self['default_ip'       ].first ; end
  def fqdn()              self['fqdn'             ].first ; end
  def availability_zone() self['availability_zone'].first ; end
  def idx()
    idx = [self['idx']].flatten.first
    idx.blank? ? nil : idx.to_i
  end

  #
  # plumbing
  #

  def self.establish_connection options={}
    return @connection if @connection
    options = { :logger => Log }.merge options
    access_key        = options[:access_key]        || Settings[:access_key]
    secret_access_key = options[:secret_access_key] || Settings[:secret_access_key]
    @connection = RightAws::ActiveSdb.establish_connection(access_key, secret_access_key, options)
  end

  #
  # Convenience for certain roles
  #

  # Register an nfs server share
  def self.register_nfs_share server_path, client_path=nil, role='nfs_server'
    client_path ||= server_path
    register(role, :server_path => server_path, :client_path => client_path)
  end

  # NFS: device path, for stuffing into /etc/fstab
  def self.nfs_device_path role='nfs_server'
    nfs_server = host(role) or return
    [nfs_server.private_ip, nfs_server[:server_path]].join(':')
  end

  #
  # Pretty print
  #

  def to_hash() attributes ; end
  def to_pretty_json
    to_hash.reject{|k,v| k.to_s == 'id'}.to_json
  end

end
