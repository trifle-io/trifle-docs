# frozen_string_literal: true

module Trifle
  module Docs
    module Harvester
      module File
        class Sieve < Harvester::Sieve
          def match?
            true
          end

          def to_url
            file.gsub(%r{^#{path}/}, '')
          end
        end

        class Conveyor < Harvester::Conveyor
          def content
            data
          end

          def meta
            {
              'path' => file,
              'type' => 'file'
            }
          end
        end
      end
    end
  end
end
