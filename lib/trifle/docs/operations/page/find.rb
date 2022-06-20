# frozen_string_literal: true

module Trifle
  module Docs
    module Operations
      module Page
        class Find
          attr_reader :url

          def initialize(**keywords)
            @url = keywords.fetch(:url)
            @config = keywords[:config]
          end

          def config
            @config || Trifle::Docs.default
          end

          def perform
            config.harvester.content_for(url: url)
          end
        end
      end
    end
  end
end
