shared_examples_for "as adapter" do
  before(:each) do
    @adapter = DataMapper.setup(:default, "groonga://#{index_path}")

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

    User.auto_migrate!
    Photo.auto_migrate!
  end

  it 'should work with a model using id' do
    u = User.create(:id => 2)
    repository.search(User, '').should == { User => [ 2 ] }
  end

  it 'should work with a model using another key than id' do
    p = Photo.create
    repository.search(Photo, '').should == { Photo => [p.uuid] }
    p.destroy!
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
