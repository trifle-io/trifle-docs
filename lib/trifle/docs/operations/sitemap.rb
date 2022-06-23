# frozen_string_literal: true

module Trifle
  module Docs
    module Operations
      class Sitemap
        def initialize(**keywords)
          @config = keywords[:config]
        end

        def config
          @config || Trifle::Docs.default
        end

        def perform
          config.harvester.sitemap
        end
      end
    end
  end
end
