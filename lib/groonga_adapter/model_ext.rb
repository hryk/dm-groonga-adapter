module DataMapper
  module Is
    module Searchable
      module ClassMethods
        def fulltext_search(query, options={})
          docs = repository(@search_repository).adapter.search(self.name, query, [], options)
          self.all(options.merge(key.first => docs.values.flatten!))
        end
      end
    end
  end
end
