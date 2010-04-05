module Broham

  def self.get_cluster_settings
    Configliere.use :commandline, :config_file
    Settings.read('broham.yaml')
    Settings.resolve!
    Settings[:cluster_name] = Settings.rest.shift
    Settings[:role_name]    = Settings.rest.shift
    check_args!
    cluster = Broham.new(Settings[:cluster_name])
    cluster.establish_connection
    cluster.create_domain
    cluster
  end

  def self.check_args!
    if (Settings[:cluster_name].blank? || Settings[:role_name].blank?)
      warn "Please supply a cluster name and a role as the first two arguments"
      exit(-1)
    end
  end

end
