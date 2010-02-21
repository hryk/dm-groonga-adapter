$KCODE = 'UTF-8'
module DataMapper
  module Adapters
    class GroongaAdapter < AbstractAdapter

      def initialize(name, options)
        super
        ctx_opts = {
          :encoding => :utf8
        }
        ctx_opts[:encoding] = @options[:encoding] if @options.key? :encoding

        @context  = Groonga::Context.default_options = ctx_opts
        @database = unless File.extname(@options[:path]) == '.sock'
                   LocalIndex.new(@options)
                 else
                   RemoteIndex.new(@options) # RemoteIndex has not been supported yet.
                 end
      end

      def create(resources)
        name = self.name

        resources.each do |resource|
          model = resource.model
          attributes = resource.attributes(:field).to_mash

          # Since we don't inspect the models before generating the indices,
          # we'll map the resource's key to the :id column.
          attributes[:id]    ||= resource.key.first
          attributes[:_type]   = model.name

          unless @database.exist_table resource.model.name
            @database.create_table(model.name,
                                   model.properties(name))
          end

          @database.add resource.model.name, attributes
        end
      end

      def read(query)
      end

      def read_many(query)
        read(query)
      end

      def read_one(query)
        read(query).first
      end

      def delete(collection)
      end

      # This returns a hash of the resource constant and the ids returned for it
      # from the search.
      #   { Story => ["1", "2"], Image => ["2"] }
      def search(groonga_query, limit = :all)
        results = {}
        @database.search(groonga_query, :limit => limit).each do |doc| 
          resources = results[Object.const_get(doc[:_table])] ||= []
          resources << doc[:id]
        end
        results
      end

      private

    end # DataMapper::Adapters::GroongaAdapter
  end
end
