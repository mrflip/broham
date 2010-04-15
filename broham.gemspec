# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{broham}
  s.version = "0.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Philip (flip) Kromer"]
  s.date = %q{2010-04-14}
  s.description = %q{Bro! Broham always knows where his bros are, bro. Using broham, a newly-created cloud machine can annouce its availability for a certain role ("nfs_server" or "db_slave-2"), allowing any other interested nodes to discover its public_ip, private_ip, etc. See also: http://j.mp/amongbros}
  s.email = %q{flip@infochimps.org}
  s.executables = ["broham", "broham-diss", "broham-fuck_all_yall", "broham-host", "broham-hosts_like", "broham-register", "broham-register_as_next", "broham-sup", "broham-sup_yall", "broham-unregister", "broham-unregister-like", "broham-yo"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.textile",
     "Rakefile",
     "VERSION",
     "bin/broham",
     "bin/broham-diss",
     "bin/broham-fuck_all_yall",
     "bin/broham-host",
     "bin/broham-register",
     "bin/broham-register_as_next",
     "bin/broham-sup",
     "bin/broham-unregister",
     "bin/broham-unregister-like",
     "bin/broham-yo",
     "broham.gemspec",
     "lib/broham.rb",
     "lib/broham/script.rb",
     "spec/broham_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/mrflip/broham}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{Broham: A simple, global, highly-available, none-too-bright service registry. Broham always knows where his bros are, bro.}
  s.test_files = [
    "spec/broham_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_development_dependency(%q<yard>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<yard>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<yard>, [">= 0"])
  end
end

