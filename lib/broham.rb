# SimpleDB interface
require 'right_aws'
require 'sdb/active_sdb'
require 'broham/sdb'

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
  def self.host role
    select_by_role(role, :order => 'timestamp DESC')
  end

  # Returns all hosts in the given role
  def self.hosts_like role
    select(:all, :order => 'timestamp DESC').select{|bro| bro[:role].to_s =~ /^#{role}/ }
  end

  def self.host_attrs(role)
    { :role => role, :timestamp => timestamp,
      :private_ip => my_private_ip, :public_ip => my_public_ip, :default_ip => my_default_ip, :fqdn => my_fqdn  }
  end

  def self.register role, attrs={}
    ahost = host(role) || new
    ahost.attributes = (host_attrs(role).merge(attrs))
    success = ahost.save
    success ? self.new(success) : false
  end

  def self.roles ip=nil
    ip ||= my_default_ip
    select_all_by_default_ip(ip).map{|entry| entry['role'] }
  end
  def self.entry_for_role role, ip=nil
    ip ||= my_default_ip
    select_by_role_and_default_ip(role, ip)
  end

  #
  # Enlists as the next among many machines filling the given role.
  #
  # This is just a simple counter: it doesn't check whether the machine is
  # already enlisted under a different index, or whether there are missing
  # indices.
  #
  # It uses conditional save to be sure that the count is consistent
  #
  def self.register_as_next role, attrs={}
    my_idx = 0
    if (registered_entry = entry_for_role(role)) then return registered_entry end
    100.times do
      ahost = host(role) || new
      current_max_idx  = ahost[:idx] && ahost[:idx].first
      my_idx           = current_max_idx ? current_max_idx.to_i + 1 : 0
      ahost.attributes = host_attrs(role).merge({ :idx => my_idx.to_s }.merge(attrs))
      expected         = current_max_idx ? {:idx => (current_max_idx.to_i).to_s} : {}
      registered_entry = ahost.save_if(expected)
      break if registered_entry
    end
    register role+'-'+my_idx.to_s, { :idx => my_idx }.merge(attrs)
    new registered_entry
  end

  #
  # Removes all registrations for the given role wildcard
  #
  def self.unregister_like role
    hosts_like(role).each(&:unregister)
  end
  def self.unregister role
    host(role).each(&:unregister)
  end
  def unregister
    delete
  end

  # alternative syntax for #register
  def self.yo!(*args)       register *args ; end
  # alternative syntax for #register_as_next
  def self.yo_yo_yo!(*args) register_as_next *args ; end
  # alternative syntax for #host
  def self.sup?(*args)      host *args    ; end
  # alternative syntax for #hosts_like
  def self.sup_yall?(*args) hosts_like *args   ; end
  # alternative syntax for #unregister
  def self.diss(*args)      unregister *args   ; end
  # alternative syntax for #unregister_like
  def self.fuck_all_yall(*args) unregister_like *args ; end

  #
  # Registration attributes
  #

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
    self['idx'].first
  end

  def self.establish_connection options={}
    options = { :logger => Log }.merge options
    access_key = options[:access_key] || Settings[:access_key]
    secret_access_key = options[:access_key] || Settings[:secret_access_key]
    @connection ||= RightAws::ActiveSdb.establish_connection(access_key, secret_access_key, options)
  end

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

  # Hadoop: master jobtracker node
  def self.hadoop_jobtracker(role='hadoop_jobtracker') ; host(role) ; end
  # Hadoop: master namenode
  def self.hadoop_namenode(  role='hadoop_namenode')   ; host(role) ; end
  # Hadoop: cloudera desktop node
  def self.cloudera_desktop( role='cloudera_desktop')  ; host(role) ; end

  def to_hash() attributes ; end
  def to_pretty_json
    to_hash.reject{|k,v| k.to_s == 'id'}.to_json
  end

end
