require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "local_index search" do
  def index_path;local_groonga_path;end

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

  it_should_behave_like "as is_search plugin"
end

describe "remote_index search" do
  def index_path;remote_groonga_path;end
  it_should_behave_like "as is_search plugin"
end

