require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "broham"
    gem.summary = %Q{Broham: A simple, global, highly-available, none-too-bright service registry. Broham always knows where his bros are, bro.}
    gem.description = %Q{Bro! Broham always knows where his bros are, bro. Using broham, a newly-created cloud machine can annouce its availability for a certain role ("nfs_server" or "db_slave-2"), allowing any other interested nodes to discover its public_ip, private_ip, etc. See also: http://j.mp/amongbros}
    gem.email = "flip@infochimps.org"
    gem.homepage = "http://github.com/mrflip/broham"
    gem.authors = ["Philip (flip) Kromer"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
