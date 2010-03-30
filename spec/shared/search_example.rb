shared_examples_for 'as is_search plugin' do

  before(:each) do
    DataMapper.setup(:default, "sqlite3::memory:")
    DataMapper.setup(:search, "groonga://#{index_path}")

    Object.send(:remove_const, :Image) if defined?(Image)
    class ::Image
      include DataMapper::Resource
      property :id, Serial
      property :title, String

      is :searchable # this defaults to :search repository, you could also do
    end

    Object.send(:remove_const, :Story) if defined?(Story)
    class ::Story
      include DataMapper::Resource
      property :id, Serial
      property :title, String
      property :author, String

      is :searchable
    end

    Story.auto_migrate!
    Image.auto_migrate!
  end

  it 'should allow search with no operator' do
    image = Image.create(:title => "Oil Rig");
    story = Story.create(:title => "Oil Rig", :author => "John Doe");
    Image.search(:title => "Oil Rig").should == [image]
  end

  it 'should allow search with :like operator' do
    image = Image.create(:title => "Oil Rig");
    Image.search(:title.like => "Oil").should == [image]
  end

end
