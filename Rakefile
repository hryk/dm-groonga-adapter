require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "dm-groonga-adapter"
    gem.summary = %Q{datamapper adapter for groonga search engine}
    gem.description = gem.summary
    gem.email = "hello@hryk.info"
    gem.homepage = "http://hryk.github.com/dm-groonga-adapter"
    gem.authors = ["hiroyuki"]

    gem.add_dependency "groonga", ">= 0.9.2"
    gem.add_dependency "dm-core", "~> 0.10.2"
    gem.add_dependency "dm-more", "~> 0.10.2"

    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "rcov", ">= 0"
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

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "dm-groonga-adapter #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

