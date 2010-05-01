module DataMapper
  module Adapters
    class GroongaAdapter < AbstractAdapter
      extend Chainable
      extend Deprecate

      # Initialize adapter
      #   
      # @param [String] name
      # @param [Hash] options the options passed to RemoteIndex or LocalIndex.
      def initialize(name, uri_or_options)
        super
        Groonga::Context.default = nil      # Reset Groonga::Context
        @database = if @options[:port].nil? # if port is nil, use local index.
                      LocalIndex.new(@options)
                    else
                      RemoteIndex.new(@options)
                    end
        @database.logger = ::DataMapper.logger
      end

      # Create groonga record from resources.
      #
      # @param  [Enumerable(Resource)] resources
      #   The list of resources (model instances) to create.
      #
      # @return [Integer]
      #   The number of records that were actually saved into the database
      def create(resources)
        name = self.name

#        resources.each do |resource|
#          model       = resource.model
#          serial      = model.serial(name)
#          attributes  = resource.dirty_attributes
#          properties  = {}
#
#          model.properties(name).each do |property|
#            bind_value = attributes[property]
#
#            # skip insering NULL for columns that are serial or without a default
#            next if bind_value.nil? && (property.serial? || !property.default?)
#
#            # if serial is being set explicitly, do not set it again
#            #
#            # (Because groonga does not have a function correspond to 
#            # SQL's AUTO_INCREMENT, serial/key MUST NOT be nil.
#            if property.equal? serial
#              serial = nil
#            end
#
#            properties[property] = bind_value
#          end
#
#          (affected_rows, insert_id) = @database.add(model, properties, serial)
#
#          if affected_rows == 1 && serial
#            serial.set!(resource, insert_id)
#          end
#        end

        resources.each do |resource|
          model = resource.model
          attributes = resource.attributes(:field).to_mash

          # Since we don't inspect the models before generating the indices,
          # we'll map the resource's key to the :id column.
          attributes[:id]    ||= resource.key.first

          @database.add model.storage_name(name), attributes
        end
      end

      # This returns an array of Groonga docs (array of Groonga::Record) which can
      # be used to instantiate objects by doc[:_type] and doc[:_id]
      def read(query) # query is DataMapper::Query
        name = self.name
        table_name = query.model.storage_name(name)
        grn_query = unless query.conditions.operands.empty?
                      create_grn_query(query)
                    else
                      ""
                    end
        grn_sort = create_grn_sort(query)
        fields = query.fields
        key    = query.model.key(name).first
        @database.search(table_name, grn_query, grn_sort).map do |lazy_doc|
          fmap = fields.map { |p|
            p_field = (p.field == "id") ? "_key" : p.field
            [ p, p.typecast(lazy_doc[p_field]) ]
          }.to_hash
          fmap.update(
            key.field => key.typecast(lazy_doc['_key'])
          )
        end
      end

      def read_many(query)
        read(query)
      end

      def read_one(query)
        read(query).first
      end

      # TODO : implement #update
      #      def update(attributes, collection)
      #        query = collection.query
      #        1
      #      end

      def delete(collection)
        name = self.name
        query      = collection.query
        table_name = query.model.storage_name(name)

        @database.delete(table_name, create_grn_query(query))
        1
      end

      # This returns a hash of the resource constant and the ids returned for it
      # from the search.
      #   { Story => ["1", "2"], Image => ["2"] }
      # query is groonga query.
      #   options are;
      #     :operator
      #     :exact
      #     :longest_common_prefix
      #     :suffix
      #     :prefix
      #     :near
      def search(model, groonga_query, groonga_sort=[], query_option={})
        results = {}

        groonga_sort = unless groonga_sort.empty?
                         groonga_sort
                       else
                         default_groonga_sort
                       end

        table_name = unless model.is_a? String
                       model.storage_name(name)
                     else
                       Object.const_get(model.to_sym).storage_name(name)
                     end

        @database.search(table_name, groonga_query, groonga_sort, query_option).each do |doc| 
          resources = results[Object.const_get(model.to_s)] ||= []
          resources << doc[:_key]
        end

        results
      end

      private

      def default_groonga_sort
        [[{:key => '_key', :order => :asc}], { :limit => -1, :offset => 0}]
      end

      def create_grn_query(query)
        conditions_statement(query.conditions)
      end

      ## from dm-ferret-adapter ##

      def conditions_statement(conditions)
        case conditions
          when Query::Conditions::NotOperation       then negate_operation(conditions)
          when Query::Conditions::AbstractOperation  then operation_statement(conditions)
          when Query::Conditions::AbstractComparison then comparison_statement(conditions)
        end
      end

      def negate_operation(operation)
        "- (#{conditions_statement(operation.operands.first)})"
      end

      def operation_statement(operation)
        statements  = []

        operation.each do |operand|
          statement = conditions_statement(operand)

          if operand.respond_to?(:operands) && operand.operands.size > 1
            statement = "(#{statement})"
          end

          statements << statement
        end

        join_with = operation.kind_of?(Query::Conditions::AndOperation) ? '+' : 'OR'
        statements.join(" #{join_with} ")
      end

      def comparison_statement(comparison)
        value = comparison.value

        # TODO: move exclusive Range handling into another method, and
        # update conditions_statement to use it

        # break exclusive Range queries up into two comparisons ANDed together
        if value.kind_of?(Range) && value.exclude_end?
          operation = Query::Conditions::BooleanOperation.new(:and,
            Query::Conditions::Comparison.new(:gte, comparison.subject, value.first),
            Query::Conditions::Comparison.new(:lt,  comparison.subject, value.last)
          )

          return "(#{operation_statement(operation)})"
        end

        operator = case comparison
          when Query::Conditions::EqualToComparison              then ''
          when Query::Conditions::InclusionComparison            then '@'
          when Query::Conditions::RegexpComparison               then raise NotImplementedError, 'no support for regexp match yet'
          when Query::Conditions::LikeComparison                 then '@'
          when Query::Conditions::GreaterThanComparison          then '>'
          when Query::Conditions::LessThanComparison             then '<'
          when Query::Conditions::GreaterThanOrEqualToComparison then '>='
          when Query::Conditions::LessThanOrEqualToComparison    then '<='
        end

        # We use property.field here, so that you can declare composite
        # fields:
        #     property :content, String, :field => "title|description"
        grn_field = (comparison.subject.field.to_s == 'id') ? '_key' : comparison.subject.field
        [ "#{grn_field}:", ((value.is_a? String) ? quote_value(value) : value) ].join(operator)
      end

      ## from dm-ferret-adapter ##

      def create_grn_sort(query)
        keys = []
        options = { :limit => -1, :offset => 0}
        options[:limit]  = query.limit unless query.limit.nil?
        options[:offset] = query.offset
        if query.order.empty?
          keys << {:key => '_key', :order => :asc}
        else
          query.order.each do |direction|
            grn_field = (direction.target.name == :id) ? '_key' : direction.target.name 
            keys << { :key => grn_field.to_s, :order => direction.operator }
          end
        end
        [ keys, options ]
      end

      def quote_value(value)
        return value.gsub(/"/, '\"').gsub(/\s/, '\ ')
      end

    end # DataMapper::Adapters::GroongaAdapter

    const_added(:GroongaAdapter)
  end
end
