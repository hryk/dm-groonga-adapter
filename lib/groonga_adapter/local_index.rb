$KCODE = "UTF-8"
module DataMapper
  module Adapters
    class GroongaAdapter::LocalIndex

      def initialize(options)
        @options = options
        create_or_init_database
        @tables = Mash.new
      end

      def add(table_name, doc)
        return unless exist_table(table_name)
        table = table(table_name)
      end

      def delete(query)
      end

      def search(query, options)
        []
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

      def create_table(model)
        @tables[model.name] = Groonga::Hash.create(
          :name       => model.name,
          :persistent => true,
          :key_type   => Groonga::Type::UINT64
        )
      end

      private

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
