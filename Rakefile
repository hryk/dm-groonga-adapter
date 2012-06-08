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

    gem.add_dependency "rroonga", "~> 2.0.4"
    gem.add_dependency "dm-core", "~> 1.2.0"
    gem.add_dependency "dm-is-searchable", "~> 1.2.0"
    gem.add_dependency "dm-sqlite-adapter", "~> 1.2.0"

    gem.add_development_dependency "rspec", "~> 2.10.0"
    gem.add_development_dependency "simplecov", ">= 0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  #spec.libs << 'lib' << 'spec'
  t.pattern = FileList['spec/**/*_spec.rb']
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

