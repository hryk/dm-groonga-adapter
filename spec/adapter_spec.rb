require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DataMapper::Adapters::GroongaAdapter do
  INDEX_PATH = Pathname(__FILE__).dirname.expand_path + 'test/index'
  it_should_behave_like "as adapter"
end
