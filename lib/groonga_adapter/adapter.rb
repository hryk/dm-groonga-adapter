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
          # attributes[:_type]   = model.name
          # $stderr.puts resource.key.first.inspect
          # $stderr.puts model.key.first.inspect
          unless @database.exist_table resource.model.name
            @database.create_table(model.name,
                                   model.properties(name),
                                   model.key.first # <- key attribute.
                                  )
          end

          @database.add model.name, attributes
        end
      end

      # This returns an array of Groonga docs (array of Groonga::Record) which can
      # be used to instantiate objects by doc[:_type] and doc[:_id]
      def read(query) # query is DataMapper::Query
        table_name = query.model.name
        grn_query = unless query.conditions.operands.empty?
                      create_grn_query(query)
                    else
                      ""
                    end
        grn_sort = create_grn_sort(query)
        @database.search(table_name, grn_query, grn_sort).map do |lazy_doc|
          fields.map { |p| [ p, p.typecast(lazy_doc[p.field]) ] }.to_hash.update(
            key.field => key.typecast(lazy_doc['_id'])
          )
        end
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
        @database.search(model.to_s, groonga_query, groonga_sort, query_option).each do |doc| 
          resources = results[Object.const_get(model.to_s)] ||= []
          resources << doc[:_id]
        end
        results
      end

      private

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
        [ "#{comparison.subject.field}:", quote_value(value) ].join(operator)
      end

      ## from dm-ferret-adapter ##

      def create_grn_sort(query)
        keys = []
        options = { :limit => -1, :offset => 0}
        options[:limit]  = query.limit unless query.limit.nil?
        options[:offset] = query.offset
        if query.order.empty?
          keys << {:key => '_id', :order => :asc}
        else
          query.order.each do |direction|
            keys << { :key => direction.to_s, :order => direction.operator }
          end
        end
        [ keys, options ]
      end

    end # DataMapper::Adapters::GroongaAdapter
  end
end
