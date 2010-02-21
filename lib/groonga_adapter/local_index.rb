$KCODE = "UTF-8"
module DataMapper
  module Adapters
    class GroongaAdapter::LocalIndex

      def initialize(options)
        @options = options
        create_or_init_database
        @tables = Mash.new
        create_or_init_term_table
      end

      def add(table_name, doc)
        return unless exist_table(table_name)
        table = table(table_name)
      end

      def delete(query)
      end

      def search(query, options)

      end

#      def [](id)
#      end

      def exist_table(table_name)
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

      def open_table(table_name)
        @tables[table_name] = Groonga::Hash.open(:name => table_name)
      end

      def create_table(table_name, properties)
        @tables[table_name] = Groonga::Hash.create(
          :name       => table_name,
          :persistent => true,
          :key_type   => Groonga::Type::UINT64
        )
        properties.each do |prop|
          type = trans_type(prop.type)
          propname = prop.name.to_s
          @tables[table_name].define_column(propname, type)
          if type == "ShortText" || type == "Text"
            index_column = add_term(table_name, propname)
          end
        end
      end

      private

      def add_term(table, prop)
        @tables['_terms'].define_index_column(
          "#{table}_#{prop}", @tables[table],
          :source => "#{table}.#{prop}"
        )
      end

      # translate DataMapper::Property::TYPES to Groonga::Type
      def trans_type(dmtype)
        case dmtype.to_s
        when 'String'
          "ShortText"
        when 'Text'
          "Text"
        when 'Float'
          "Float"
        when 'Bool'
          "Bool"
        when 'Integer'
          "Int32"
        when 'BigDecimal'
          "Int64"
        when 'Serial'
          "Int32"
        when 'Time'
          "Time"
        else
          "ShortText"
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
        unless exist_table('_terms')
          @tables['_terms'] = Groonga::Hash.create(:name       => "_terms",
                                                   :persistent => true,
                                                   :key_type   => Groonga::Type::UINT64,
                                                   :default_tokenizer => "TokenBigram")
        else
          open_table('_terms')
        end
      end

      def create_or_init_database
        # try to open database.
        path = Pathname(@options[:path])
        begin
          @database = Groonga::Database.open(path.to_s)
        rescue => e
          STDERR.puts "try create database. #{e}"
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
