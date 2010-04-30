$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
SPEC_ROOT = Pathname(__FILE__).dirname.expand_path

require 'rubygems'
require 'uuidtools'
require 'dm-core'
require 'dm-is-searchable'
require 'spec'
require 'spec/autorun'

(Pathname.new(__FILE__).parent + "shared").children.grep(/\.rb$/).each do |example|
  puts example
  require example
end

def load_driver(name, default_uri)
  return false if ENV['ADAPTER'] != name.to_s

  begin
    DataMapper.setup(name, ENV["#{name.to_s.upcase}_SPEC_URI"] || default_uri)
    DataMapper::Repository.adapters[:default] =  DataMapper::Repository.adapters[name]
    true
  rescue LoadError => e
    warn "Could not load do_#{name}: #{e}"
    false
  end
end

ENV['ADAPTER'] ||= 'sqlite3'

HAS_SQLITE3  = load_driver(:sqlite3,  'sqlite3::memory:')
HAS_MYSQL    = load_driver(:mysql,    'mysql://localhost/dm_core_test')
HAS_POSTGRES = load_driver(:postgres, 'postgres://postgres@localhost/dm_core_test')

def local_groonga_path
  Pathname(SPEC_ROOT) + 'test/index'
end
def remote_groonga_path
  ENV["DM_GRN_URL"] || "127.0.0.1:10041" # "192.168.81.132:8888" <- 1.4.0
end

# Spec::Runner.configure do |config|
# end
