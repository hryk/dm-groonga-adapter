require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "local_index adapter" do
  def index_path
    Pathname(__FILE__).dirname.expand_path + 'test/index'
  end

  after(:all) do
    Pathname.new(index_path).parent.children.each do |f|
      f.delete
    end
  end

  before(:each) do
    # remove indeces before running spec.
    Pathname.new(index_path).parent.children.each do |f|
      f.delete
    end
  end

  it_should_behave_like "as adapter"
end

describe "remote_index adapter" do
  def index_path
    ENV["DM_GRN_URL"] || "192.168.81.132:8888"
  end
  it_should_behave_like "as adapter"
end
