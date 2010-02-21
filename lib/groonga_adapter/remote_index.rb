module DataMapper
  module Adapters
    class GroongaAdapter::RemoteIndex

      def initialize(options)
        @options = options
        @database = nil
        @tables = Mash.new
      end

      def add(table_name, doc)
      end

      def delete(query)
      end

      def search(query, options)
      end

#      def [](id)
#      end

      def exist_table(table_name)
      end

      def open_table(table_name)
      end

      def create_table(model)
      end

      private

#      def table(table_name)
#      end

    end
  end
end
