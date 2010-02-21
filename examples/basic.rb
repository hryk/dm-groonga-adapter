require 'rubygems'
require 'dm-core'
require 'dm-is-searchable'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'groonga_adapter'

DataMapper.setup(:default, "sqlite3::memory:")
DataMapper.setup(:search, "groonga://#{Pathname(__FILE__).dirname.expand_path + "test/db"}")

class Image
  include DataMapper::Resource
  property :id, Serial
  property :title, String

  is :searchable # this defaults to :search repository, you could also do
  # is :searchable, :repository => :ferret

end

class Story
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :author, String

#  repository(:search) do
#    # We only want to search on id and title.
#    #properties(:search).clear
#    property :id, Serial
#    property :title, String
#  end

  is :searchable
end

Image.auto_migrate!
Story.auto_migrate!

image = Image.create(:title => "Oil Rig");
story = Story.create(:title => "Oil Rig", :author => "John Doe");

puts Image.search(:title => "Oil Rig").inspect # => [<Image title="Oil Rig">]

