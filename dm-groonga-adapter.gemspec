# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-groonga-adapter}
  s.version = "0.1.0.pre2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["hiroyuki"]
  s.date = %q{2010-04-15}
  s.description = %q{datamapper adapter for groonga search engine}
  s.email = %q{hello@hryk.info}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION.yml",
     "dm-groonga-adapter.gemspec",
     "examples/basic.rb",
     "lib/groonga_adapter.rb",
     "lib/groonga_adapter/adapter.rb",
     "lib/groonga_adapter/jsonparser.rb",
     "lib/groonga_adapter/local_index.rb",
     "lib/groonga_adapter/model_ext.rb",
     "lib/groonga_adapter/remote_index.rb",
     "lib/groonga_adapter/remote_result.rb",
     "lib/groonga_adapter/repository_ext.rb",
     "lib/groonga_adapter/unicode_ext.rb",
     "spec/rcov.opts",
     "spec/shared/adapter_example.rb",
     "spec/shared/search_example.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "spec/specs/adapter_spec.rb",
     "spec/specs/remote_result_spec.rb",
     "spec/specs/search_spec.rb"
  ]
  s.homepage = %q{http://hryk.github.com/dm-groonga-adapter}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{datamapper adapter for groonga search engine}
  s.test_files = [
    "spec/shared/adapter_example.rb",
     "spec/shared/search_example.rb",
     "spec/spec_helper.rb",
     "spec/specs/adapter_spec.rb",
     "spec/specs/remote_result_spec.rb",
     "spec/specs/search_spec.rb",
     "examples/basic.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<groonga>, [">= 0.9"])
      s.add_runtime_dependency(%q<dm-core>, ["~> 0.10.2"])
      s.add_runtime_dependency(%q<dm-more>, ["~> 0.10.2"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<groonga>, [">= 0.9"])
      s.add_dependency(%q<dm-core>, ["~> 0.10.2"])
      s.add_dependency(%q<dm-more>, ["~> 0.10.2"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<groonga>, [">= 0.9"])
    s.add_dependency(%q<dm-core>, ["~> 0.10.2"])
    s.add_dependency(%q<dm-more>, ["~> 0.10.2"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

