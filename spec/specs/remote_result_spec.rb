require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'json'

describe "DataMapper::Adapters::GroongaAdapter::GroongaResult" do

  it "should parse status result" do
    raw_value = JSON.parse '[[0,1270195421.18934,7.0e-05],{"alloc_count":143,"starttime":1270022695,"uptime":172726,"version":"0.1.7"}]'
    status = DataMapper::Adapters::GroongaResult::Status.new raw_value
    status.success?.should == true
    status.err_code.should == 0
    status.err_msg.should == nil
    status.start_time.should == 1270195421.18934
    status.elapsed_time == 7.0e-05
    status.alloc_count.should == 143
    status.process_starttime.should == 1270022695
    status.uptime.should == 172726
    status.version.should == '0.1.7'
  end

  it "should parse result with err_code" do
    raw_value = JSON.parse '[[-22,1270196259.75858,0.00035,"table \'Hoge\' is not exist."]]'
    err_result = DataMapper::Adapters::GroongaResult::List.new raw_value
    err_result.success?.should == false
    err_result.err_code.should == -22
    err_result.err_msg.should == "table 'Hoge' is not exist."
    err_result.start_time.should == 1270196259.75858
  end

  it "should parse column_list result" do
    raw_value = JSON.parse '[[0,1270196657.83001,0.000183],[[["id", "UInt32"],["name","ShortText"],["path","ShortText"],["type","ShortText"],["flags","ShortText"],["domain", "ShortText"],["range", "ShortText"],["source","ShortText"]],[273,"Story.title","test.0000111","var","COLUMN_SCALAR|COMPRESS_NONE|PERSISTENT","Story","ShortText",[]],[272,"Story.id","test.0000110","fix","COLUMN_SCALAR|COMPRESS_NONE|PERSISTENT","Story","Int32",[]],[275,"Story.author","test.0000113","var","COLUMN_SCALAR|COMPRESS_NONE|PERSISTENT","Story","ShortText",[]]]]'
    column_list = DataMapper::Adapters::GroongaResult::List.new raw_value

    column_list.success?.should == true
    column_list.err_code.should == 0
    column_list.err_msg.should == nil
    column_list.start_time.should == 1270196657.83001
    column_list.elapsed_time == 0.000183

    column_list.columns.should == ["id", "name", "path", "type", "flags", "domain", "range", "source"]
    expect_mash = Mash.new({
      "id" => 273,
      "name" => "Story.title",
      "path" => "test.0000111",
      "type" => 'var',
      "flags" => "COLUMN_SCALAR|COMPRESS_NONE|PERSISTENT",
      "domain" => "Story",
      "range" => "ShortText",
      'source' => []
    })
    column_list.select{|row| row[:name] == "Story.title"}.should == [ expect_mash ]
  end

  it "should parse table_list result" do
    raw_value = JSON.parse '[[0,1270197916.25107,0.000215],[[["id", "UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain", "ShortText"],["range","ShortText"]],[259,"DMGTerms","test.0000103","TABLE_PAT_KEY|KEY_NORMALIZE|PERSISTENT","ShortText","null"],[267,"Image","test.000010B","TABLE_HASH_KEY|PERSISTENT","Int32","null"],[261,"Photo","test.0000105","TABLE_HASH_KEY|PERSISTENT","ShortText","null"],[271,"Story","test.000010F","TABLE_HASH_KEY|PERSISTENT","Int32","null"],[256,"User","test.0000100","TABLE_HASH_KEY|PERSISTENT","Int32","null"]]]'

    table_list = DataMapper::Adapters::GroongaResult::List.new raw_value

    table_list.success?.should == true
    table_list.err_code.should == 0
    table_list.err_msg.should == nil
    table_list.start_time.should == 1270197916.25107
    table_list.elapsed_time == 0.000215

    table_list.map{|row| row[:name] }.should == [ 'DMGTerms', 'Image', 'Photo', 'Story', 'User' ]
  end

  it "should parse select result" do
    raw_value = JSON.parse '[[0,1270198116.95839,0.000182],[[[2],[["_id","UInt32"],["_key","ShortText"],["uuid","ShortText"],["happy","Bool"],["description","ShortText"]],[1,"2693a46f-ed73-4200-895c-211a49152077","2693a46f-ed73-4200-895c-211a49152077",true,"null"],[2,"93df38eb-c834-4ec3-9949-72c72760ceb7","93df38eb-c834-4ec3-9949-72c72760ceb7",true,"null"]]]]'
    table_list = DataMapper::Adapters::GroongaResult::List.new raw_value
    table_list.size.should == 2
    table_list.map{|row| row[:happy] }.should == [true, true]
  end

  it "should parse load result" do
    raw_value = JSON.parse '[[0,1270199923.22467,5.2e-05],1]'
    res = DataMapper::Adapters::GroongaResult::Count.new raw_value
    res.count.should == 1
  end
end

__END__

table_list
[
  [["id", "UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain", "ShortText"],["range","ShortText"]],
  [259,"DMGTerms","test.0000103","TABLE_PAT_KEY|KEY_NORMALIZE|PERSISTENT","ShortText","null"],
  [267,"Image","test.000010B","TABLE_HASH_KEY|PERSISTENT","Int32","null"],
  [261,"Photo","test.0000105","TABLE_HASH_KEY|PERSISTENT","ShortText","null"],
  [271,"Story","test.000010F","TABLE_HASH_KEY|PERSISTENT","Int32","null"],
  [256,"User","test.0000100","TABLE_HASH_KEY|PERSISTENT","Int32","null"]]
]
select Photo
[
  [
    [2],
    [["_id","UInt32"],["_key","ShortText"],["uuid","ShortText"],["happy","Bool"],["description","ShortText"]],
    [1,"2693a46f-ed73-4200-895c-211a49152077","2693a46f-ed73-4200-895c-211a49152077",true,"null"],
    [2,"93df38eb-c834-4ec3-9949-72c72760ceb7","93df38eb-c834-4ec3-9949-72c72760ceb7",true,"null"]
  ]
]
