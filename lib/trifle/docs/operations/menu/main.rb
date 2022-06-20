# frozen_string_literal: true

module Trifle
  module Docs
    module Operations
      module Menu
        class Main
          def initialize(**keywords)
            @config = keywords[:config]
          end

          def config
            @config || Trifle::Docs.default
          end

          def perform
            # TODO: Implement
          end
        end
      end
    end
  end
end
