# frozen_string_literal: true

module Trifle
  module Docs
    module Operations
      class Search
        attr_reader :query

        def initialize(**keywords)
          @query = keywords.fetch(:query)
          @config = keywords[:config]
        end

        def config
          @config || Trifle::Docs.default
        end

        def perform
          config.harvester.search_for(query: query)
        end
      end
    end
  end
end
