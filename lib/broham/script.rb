require 'json'
Configliere.use :config_file, :commandline, :git_style_binaries

class Broham < RightAws::ActiveSdb::Base
end

class BrohamScript

  # Dump a list of hashes as a formatted, equally-spaced table
  def self.dump_table hosts_list
    attr_lens = {}
    # find all used fields, and their width
    hosts_list.each do |host|
      host.to_hash.each{|k,v| attr_lens[k] = [v.to_s.length, attr_lens[k].to_i].max }
    end
    # account for length of attr titles
    attr_lens.each{|attr,len| attr_lens[attr] = [len, attr.length].max }
    # take attrs in order, putting role first (and excluding id)
    attrs = ['role', (attr_lens.keys - ['role', 'id']).sort].flatten
    $stderr.puts attrs.map{|attr| "%-#{attr_lens[attr]}s"%attr}.join("\t")
    hosts_list.each do |host|
      $stdout.puts attrs.map{|attr| "%-#{attr_lens[attr]}s"%host[attr]}.join("\t")
    end
  end

end
