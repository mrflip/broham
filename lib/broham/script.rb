class Broham < RightAws::ActiveSdb::Base

  def self.get_cluster_settings
    Configliere.use :commandline, :config_file
    Settings.read('broham.yaml')
    Settings.resolve!
    self.establish_connection
  end

  def self.get_command_line_args *arg_names
    arg_names.each do |arg_name|
      Settings[arg_name] = Settings.rest.shift
    end
    check_args! *arg_names
  end

  def self.check_args! *arg_names
    if Settings[:role_name].blank?
      warn "Please supply a role as the first argument"
      exit(-1)
    end
  end

end
