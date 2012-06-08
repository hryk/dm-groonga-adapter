# encoding: utf-8
shared_examples_for 'as is_search plugin' do

  before(:each) do
    DataMapper.setup(:default, "sqlite3::memory:")
    DataMapper.setup(:search, "groonga://#{index_path}")
#    DataMapper::Logger.new($stderr, :debug)
    Object.send(:remove_const, :Image) if defined?(Image)
    class ::Image
      include DataMapper::Resource
      property :id, Serial
      property :title, String
      property :description, Text
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
    Story.auto_migrate!(:search)
    Image.auto_migrate!
    Image.auto_migrate!(:search)
  end

  it 'should allow search with no operator' do

    pending "grn expression may have bug." # FIXME

    image = Image.create(:title => "Oil Rig");
    story = Story.create(:title => "Oil Rig",
                         :author => "John Doe");
    Image.search(:title => "Oil Rig").should == [image]
  end

  it 'should allow search with :like operator' do
    image = Image.create(:title => "Oil Rig");
    Image.search(:title.like => "Oil").should == [image]
    image.title = "Owl Owl"
    image.save
    Image.search(:title.like => "Owl").should == [image]
  end

  it "should allow search with japanese" do
    image = Image.create(:title => "お腹すいた");
    Image.search(:title.like => "お腹").should == [image]
    image.title = "すいてない"
    image.save
    Image.search(:title.like => "すいてない").should == [image]
  end

  it 'should allow search with all columns' do
    story = Story.create(:title  => "Oil Rig",
                         :author => "John Doe");
    story2 = Story.create(:title => "Lolem ipsum",
                         :author => "John Doe");
    # Story.fulltext_search("John").should == [story, story2] # <--- Crash on local index.
    Story.fulltext_search("author:@John").should == [story, story2]
  end

  it 'should return all result when there is more than 10 result' do
    suffix = (0..10).map {|i| "long description." }
    (0..157).each do |num|
      img = Image.create(:title => "Picture_#{num}", :description => "#{suffix}")
      img.save
    end
    results = Image.search(:title.like => "Picture")
    results.size.should == 158
  end
end

