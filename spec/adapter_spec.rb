require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

INDEX_PATH = Pathname(__FILE__).dirname.expand_path + 'test/index'

describe DataMapper::Adapters::GroongaAdapter do
  before do
    # remove indeces before running spec.
    Pathname.new(INDEX_PATH).parent.children.each do |f|
      f.delete
    end

    @adapter = DataMapper.setup(:default, "groonga://#{INDEX_PATH}")

    Object.send(:remove_const, :User) if defined?(User)
    class ::User
      include DataMapper::Resource

      property :id, Serial
      property :name, String
    end

    Object.send(:remove_const, :Photo) if defined?(Photo)
    class ::Photo
      include DataMapper::Resource

      property :uuid, String, :default => proc { UUIDTools::UUID.random_create }, :key => true
      property :happy, Boolean, :default => true
      property :description, String
    end
  end

  it 'should work with a model using id' do
    u = User.create(:id => 2)
    repository.search(User, '').should == { User => [ 2 ] }
  end

  it 'should work with a model using another key than id' do
    p = Photo.create
    repository.search(Photo, '').should == { Photo => [p.uuid] }
  end

  it 'should allow lookups using Model#get' do
    u = User.create(:id => 2, :name => "foovarbuz")
    User.get(2).should == u
  end

  it 'should allow delete rows using Model#destroy' do
    u  = User.create(:id => 2, :name => "Alice")
    u2 = User.create(:id => 3, :name => "Bob")
    User.get(2).should == u
    bob = User.get(3)
    repository.search(User,'name:Bob').should == { User => [ 3 ] } #[User].size.should == 1
    bob.destroy!.should == true
    repository.search(User,'name:Bob').should == {}
    repository.search(User,'name:Alice').should == {User => [ 2 ]}
  end

end
