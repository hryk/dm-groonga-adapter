shared_examples_for "migrations" do
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
  end

  it 'should respond to migration methods' do
    DataMapper.repository(:default).adapter.respond_to?( :storage_exists? ).should == true 
    DataMapper.repository(:default).adapter.respond_to?( :field_exists? ).should == true
    DataMapper.repository(:default).adapter.respond_to?( :upgrade_model_storage ).should == true
    DataMapper.repository(:default).adapter.respond_to?( :create_model_storage ).should == true
    DataMapper.repository(:default).adapter.respond_to?( :destroy_model_storage ).should == true
  end

  it 'should work auto_migration' do
    User.auto_migrate!
    Photo.auto_migrate!
  end
end
