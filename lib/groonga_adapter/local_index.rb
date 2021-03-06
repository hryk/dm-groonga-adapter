module DataMapper
  module Adapters
    class GroongaAdapter::LocalIndex
      attr_accessor :logger

      def initialize(options)
        @options = options
        @tokenizer = if options.key? :tokenizer
                       options[:tokenizer]
                     else
                       "TokenBigram"
                     end
        @context = Groonga::Context.default
        create_or_init_database
        @tables = Mash.new
        @binding_version = Groonga::BINDINGS_VERSION.inject(0){|r, item|
          r += item * (10 ** (Groonga::BINDINGS_VERSION.size - Groonga::BINDINGS_VERSION.index(item) - 1))
        }
        create_or_init_term_table
      end

      def add(table_name, doc)
        return unless exist_table(table_name)
        table = table(table_name)
        doc_id = doc.delete(:id)
        record = table.add(doc_id)

        doc.each do |k, v|
          begin
            if record.have_column? k
              record[k] = v
            else
              puts "column #{k} is not defined."
            end
          rescue => e
            puts record.inspect
            puts record.columns.inspect
            puts k
            puts v
            raise e
          end
        end
        doc
      end

      # FIXME : WTF.
      def delete(table_name, grn_query)
        unless grn_query.empty?
          # table = @tables[table_name]
          ids = {}
          # WTF start
          @tables[table_name].select(grn_query, {}).records.each {|r|
            # r.delete <-- Not work.
            # ids[r[:dmid]] == true
            ids[r['_key']] = true
          }
          @tables[table_name].records.each {|r|
            # if ids[r[:dmid]] == true
            if ids[r['_key']] == true
              r.delete
            end
          }
          # WTF end
          #ids.each { |id| @tables[table_name].delete id }
        end
        1
      end

      # table_name : String
      # grn_query  : String (e.g., "title:@foovar"
      # grn_sort   : [{:key => "_id", :order => :asc }]
      def search(table_name, grn_query, grn_sort=[], options={})
        table = @tables[table_name]
        table = @tables[table_name].select(grn_query, options) unless grn_query.empty?

        if grn_sort.empty?
          grn_sort << {:key => "_key", :order => :asc }
        end
        table.sort(*grn_sort)
      end

      def exist_table(table_name)
        if !@binding_version.nil? and @binding_version >= 95
          if @context[table_name].nil?
            return false
          else
            return true
          end
        else
          begin
            Groonga::Hash.open(:name => table_name)
          rescue Groonga::InvalidArgument
            return false
          rescue => e
            raise e
          else
            return true
          end
        end
      end

      def open_table(table_name)
        if !@binding_version.nil? and @binding_version >= 95
            @context[table_name]
        else
          Groonga::Hash.open(:name => table_name)
        end
      end

      def create_table(table_name, properties)
        key_prop = properties.key.first
        key_type = (key_prop.nil?) ? Groonga::Type::UINT64 : trans_type(key_prop.type)
        @tables[table_name] = Groonga::Hash.create(
          :name       => table_name,
          :persistent => true,
          :key_type   => key_type
        )

        # add columns
        properties.each do |prop|
          create_column(table_name, prop)
        end
      end

      def destroy_table(table_name)
        return true unless exist_table table_name
        @tables[table_name].remove()
        true
      end

      def create_column(table_name, property)
        type = trans_type(property.type)
        propname = property.name.to_s
        @tables[table_name].define_column(propname, type, {:persistent => true})
        if type == "ShortText" || type == "Text" || type == "LongText"
          index_column = add_term(table_name, propname)
        end
      end

      private

      def add_term(table, prop)
        @tables['DMGterms'].define_index_column(
          "#{table}_#{prop}", @tables[table],
          :source => "#{table}.#{prop}"
        )
      end

      # translate DataMapper::Property::TYPES to Groonga::Type
      def trans_type(dmtype)
        case dmtype.to_s
        when 'String'
          return Groonga::Type::SHORT_TEXT
        when 'Text'
          return Groonga::Type::TEXT
        when 'Float'
          return Groonga::Type::FLOAT
        when 'Bool'
          return Groonga::Type::BOOL
        when 'Boolean'
          return Groonga::Type::BOOLEAN
        when 'Integer'
          return Groonga::Type::INT32
        when 'BigDecimal'
          return Groonga::Type::INT64
        when 'Time'
          return Groonga::Type::TIME
        when /^DataMapper::Types::(.+)$/
          case $1
          when "Boolean"
            return Groonga::Type::BOOL
          when "Serial"
            return Groonga::Type::UINT32
          when "Text"
            return Groonga::Type::TEXT
          end
        else
          return Groonga::Type::SHORT_TEXT
        end
      end

      def table(table_name)
        unless @tables.key? table_name
          if exist_table(table_name)
            open_table(table_name)
          else
            false # no such table.
          end
        end
        return @tables[table_name]
      end

      def create_or_init_term_table
        unless exist_table('DMGterms')
          @tables['DMGterms'] = Groonga::Hash.create(:name              => "DMGterms",
                                                     :persistent        => true,
                                                     :key_type          => Groonga::Type::UINT64,
                                                     :default_tokenizer => @tokenizer)
        else
          open_table('DMGterms')
        end
      end

      def create_or_init_database
        # try to open database.
        path = Pathname(@options[:path])

        if path.exist? && path.file?
          # open database
          if !@binding_version.nil? and @binding_version >= 95
            @database = Groonga::Database.new(path.to_s)
          else
            @database = Groonga::Database.open(path.to_s)
          end
        else
          # check directory.
          unless path.dirname.directory?
            path.dirname.mkpath
          end
          # create database.
          @database = Groonga::Database.create(:path => path.to_s)
        end
      end

    end
  end
end
