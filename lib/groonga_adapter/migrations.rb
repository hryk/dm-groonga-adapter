module DataMapper
  module Migrations
    module GroongaAdapter
#      def self.included(base)
#        DataMapper.extend(Migrations::SingletonMethods)
#
#        [ :Repository, :Model ].each do |name|
#          DataMapper.const_get(name).send(:include, Migrations.const_get(name))
#        end
#      end

      # Returns whether the storage_name exists.
      #
      # @param [String] storage_name
      #   a String defining the name of a storage, for example a table name.
      #
      # @return [Boolean]
      #   true if the storage exists
      #
      # @api semipublic
      def storage_exists?(storage_name)
        @database.exist_table(storage_name)
      end

      # Returns whether the field exists.
      #
      # @param [String] storage_name
      #   a String defining the name of a storage, for example a table name.
      # @param [String] field
      #   a String defining the name of a field, for example a column name.
      #
      # @return [Boolean]
      #   true if the field exists.
      #
      # @api semipublic
      def field_exists?(storage_name, field)
        @database.exist_column(storage_name, field)
      end

      # @api semipublic
      def upgrade_model_storage(model)
        name       = self.name
        properties = model.properties_with_subclasses(name)

        if success = create_model_storage(model)
          return properties
        end

        table_name = model.storage_name(name)

          properties.map do |property|
            schema_hash = property_schema_hash(property)
            next if field_exists?(table_name, schema_hash[:name])

            @database.create_column(table_name, property)
         
            property
          end.compact
      end

      # @api semipublic
      def create_model_storage(model)
        name       = self.name
        properties = model.properties_with_subclasses(name)
        table_name = model.storage_name(name)

        return false if storage_exists?(table_name)
        return false if properties.empty?
        
        @database.create_table(table_name, properties)
        true
      end

      # @api semipublic
      def destroy_model_storage(model)
        return true unless storage_exists?(model.storage_name(name))
        name = self.name
        table_name = model.storage_name(name)
        @database.destroy_table(table_name)
        true
      end

    end
  end
end
