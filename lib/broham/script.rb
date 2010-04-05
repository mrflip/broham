class Broham < RightAws::ActiveSdb::Base

  def self.get_cluster_settings
    Configliere.use :commandline, :config_file
    Settings.read('broham.yaml')
    Settings.resolve!
    Settings[:role_name]    = Settings.rest.shift
    check_args!
    self.establish_connection
  end

  def self.check_args!
    if Settings[:role_name].blank?
      warn "Please supply a role as the first argument"
      exit(-1)
    end
  end

end
