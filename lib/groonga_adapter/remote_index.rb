require 'json'
require 'nkf'

module DataMapper
  module Adapters
    class GroongaAdapter::RemoteIndex
      extend Deprecate
      attr_accessor :logger
      attr_accessor :context

      def initialize(options)
#        $stderr.puts options.inspect
        @tokenizer = if options.key? :tokenizer
                       options[:tokenizer]
                     else
                       "TokenBigram"
                     end
        @context = Groonga::Context.default
        @context.connect(:host => options[:host], :port => options[:port])
        @jsonbuilder = JsonBuilder.new
        status = GroongaResult::Status.new( request "status" )

        unless status.success?
          throw status.err_msg
        else
          @grn_version = status.version
        end

        self
      end

      def add(table_name, doc)
        return unless exist_table(table_name)
        doc_id = doc[:id] #doc.delete(:id)
        record = []
        record << doc.update("_key" => doc_id)
        values = escape_value record
        res = request "load --table #{table_name} --values #{values}"
        result = GroongaResult::Count.new res
        if result.success? && result.count > 0
          return doc
        else
          throw "failed to load record. : #{result.err_code}"
        end
      end

      def delete(table_name, grn_query)
        self.search(table_name, grn_query).each do |i|
          request "delete #{table_name} --id #{i['_id']}"
        end
      end

      # select table [match_columns [query [filter [scorer [sortby [output_columns
      #              [offset [limit [drilldown [drilldown_sortby [drilldown_output_columns
      #                           [drilldown_offset [drilldown_limit [output_type]]]]]]]]]]]]]]
      def search(table_name, grn_query, grn_sort=[], options={})
        # In case of columns contain long string, groonga return 10 results with no-limit..
        # --limit #{num} option is needed to get all result.
        # because of this, current remote_index request at twice.
        sort_by, offset, limit = parse_grn_sort grn_sort
        remote_query     = (grn_query.empty?) ? "" : "--query #{grn_query}"
        remote_sort_by   = (sort_by.empty?)   ? "" : "--sortby #{sort_by}"
        # 1st request for get count.

        if limit.nil? or limit == -1
          count = GroongaResult::List.new(request "select #{table_name} #{remote_query} #{remote_sort_by} --output_columns _id")
          limit = count.size
        end

        # 2nd request for get ids.
        res = request "select #{table_name} #{remote_query} #{remote_sort_by} --offset #{offset} --limit #{limit}"
        list = GroongaResult::List.new res
        if list.success?
          return list.to_a
        else
          throw list.err_msg
        end
      end

      def exist_table(table_name)
        res = request "table_list"
        table_list = GroongaResult::List.new res
        if table_list.success?
          existence = false
          table_list.each do |row|
            existence = true if row[:name] == table_name
          end
          return existence
        else
          throw table_list.err_msg
        end
      end

      def exist_column(table_name, column_name)
        # groonga 1.4
        #   [["id","name","path","type","flags","domain"],[260,"title","test.0000104","var",49152,259]]
        # groonga 1.7
        #   [
        #    [0,1269972586.4569,1.4e-05],
        #    [[["id", "UInt32"],["name","ShortText"],["path","ShortText"],["type","ShortText"],["flags","ShortText"],["domain", "ShortText"],["range", "ShortText"],["source","ShortText"]]]
        #    ]
        res = request "column_list #{table_name}"
        list = GroongaResult::List.new res
        if list.success?
          existence = false
          list.each do |row|
            existence = true if row[:name] == column_name
          end
          existence
        else
          throw list.err_msg
        end
      end

      def create_table(table_name, properties)
        key_prop = properties.key.first
        key_type = (key_prop.nil?) ? "UInt64" : trans_type(key_prop.type)
        # create table
        res = request "table_create #{table_name} 0 #{key_type}";
        result = GroongaResult::Base.new res
        throw result.err_msg unless result.err_code == 0 || result.err_code == -22

        properties.each do |prop|
          create_column(table_name, prop)
        end
      end

      def destroy_table(table_name)
        return true unless exist_table(table_name)
        res = GroongaResult::Base.new( request "table_remove #{table_name}" )
        if res.success?
          return true
        else
          throw "Destroy table failed : #{res.inspect} : #{query}"
        end
      end

      def create_column(table_name, property)
          type = trans_type(property.type)
          propname = property.name.to_s

          query = "column_create #{table_name} #{propname} 0 #{type}"
          res = GroongaResult::Base.new(request query)
          err = res.err_code

          unless err == 0 || err == -22
            throw "Create Column Failed : #{res.inspect} : #{query}"
          end

          if type == "ShortText" || type == "Text" || type == "LongText"
            add_term(table_name, propname)
          end
      end

      protected

      def escape_value record
        record.map! {|r|
          tmp = {}
          r.each {|k,v|
            if !v.nil?
              if v.is_a? String
                tmp[k] = NKF.nkf('-wZ1',v)
                tmp[k].gsub!(/\\/, '\\\\\\')
                tmp[k].gsub!(/"/) { |c| "\\\\\\#{c}" }
              else
                tmp[k] = v.to_s
              end
            end
          }
          tmp
        }
        json = @jsonbuilder.build record
        json.gsub!(/'|\s|\(|\)|\t/) { |c| "\\#{c}" }
        json
      end

      def trans_type(dmtype)
        case dmtype.to_s
        when 'String'
          return 'ShortText'
        when 'Text'
          return 'Text'
        when 'Float'
          return 'Float'
        when 'Bool'
          return 'Bool'
        when 'Boolean'
          return 'Bool'
        when 'Integer'
          return 'Int32'
        when 'BigDecimal'
          return 'Int64'
        when 'Time'
          return 'Time'
        when /^DataMapper::Types::(.+)$/
          case $1
          when "Boolean"
            return 'Bool'
          when "Serial"
            return 'Int32'
          when "Text"
            return "Text"
          end
        else
          return 'ShortText'
        end
      end

      def create_term_table(table_name, key_prop="ShortText")
        res = request "table_create #{table_name} TABLE_PAT_KEY|KEY_NORMALIZE #{key_prop} Void #{@tokenizer}"
        result = GroongaResult::Base.new res
        throw "Fale to create term table." unless result.err_code == 0 || result.err_code == -22
        true
      end

      def add_term(table_name, propname)
        term_table_name = 'DMGTerms'
        term_column_name = "#{table_name.downcase}_#{propname.downcase}"
        # check existence of term table
        unless exist_table term_table_name
          create_term_table term_table_name
        end
        # check existence of column in term table
        unless exist_column(term_table_name, term_column_name)
          request "column_create DMGTerms #{term_column_name} COLUMN_INDEX|WITH_POSITION #{table_name} #{propname}"
        end
      end

      def request(message)
        @context.send message
        @logger.debug( "Query: " + message ) if !@logger.nil?
        id, result = @context.receive
        @logger.debug( "Result: " + result ) if !@logger.nil?
        if result == 'true'
          true
        elsif result == 'false'
          false
        else
          JSON.parse(result)
        end
      end

      def parse_grn_sort(grn_sort=[])
        return "" if grn_sort == []
        sort = grn_sort[0]
        options = grn_sort[1]
        sort_str = sort.map {|i|
          desc = (i[:order] == :desc) ? '-' : ''
          "#{desc}#{i[:key]}"
        }.join(',')
        [ sort_str, options[:offset], options[:limit] ]
      end

    end # class GroongaAdapter::RemoteIndex
  end # module Adapters
end # module DataMapper

__END__

Commands

add
column_create
column_list
define_selector
delete
get
load
log_level
log_put
log_put
quit
select
set
shutdown
status
table_create
table_list
view_add

Types

Object        任意のテーブルに属する全てのレコード [1]
Bool          bool型。trueとfalse。
Int8          8bit符号付き整数。
UInt8         8bit符号なし整数。
Int16         16bit符号付き整数。
UInt16        16bit符号なし整数。
Int32         32bit符号付き整数。
UInt32        32bit符号なし整数。
Int64         64bit符号付き整数。
UInt64        64bit符号なし整数。
Float         ieee754形式の64bit浮動小数点数。
Time          1970年1月1日0時0分0秒からの経過マイクロ秒数を
64bit符号付き整数で表現した値。
ShortText     4Kbyte以下の文字列。
Text          64Kbyte以下の文字列。
LongText      2Gbyte以下の文字列。
TokyoGeoPoint 日本測地系緯度経度座標。
WGS84GeoPoint 世界測地系緯度経度座標。
