# frozen_string_literal: true

module Trifle
  module Docs
    module Operations
      class Search
        attr_reader :query, :scope

        def initialize(**keywords)
          @query = keywords.fetch(:query)
          @scope = keywords[:scope] # Optional scope to limit search to subfolder
          @config = keywords[:config]
        end

        def config
          @config || Trifle::Docs.default
        end

        def perform
          config.harvester.search_for(query: query, scope: scope)
        end
      end
    end
  end
end
