# frozen_string_literal: true

module Trifle
  module Docs
    module Helper
      class Tree
        attr_reader :mapping

        def initialize(mapping:)
          @mapping = mapping
        end

        def menu
          @menu ||= mapping.inject({}) do |out, (url, meta)|
            deep_merge(
              out, url.split('/').reverse.inject({'_meta' => meta}) { |o, k| { k => o } }
            )
          end
        end

        def deep_merge(this_hash, other_hash, &block)
          deep_merge!(this_hash.dup, other_hash, &block)
        end

        def deep_merge!(this_hash, other_hash, &block)
          this_hash.merge!(other_hash) do |key, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              deep_merge(this_val, other_val, &block)
            elsif block_given?
              block.call(key, this_val, other_val)
            else
              other_val
            end
          end
        end
      end
    end
  end
end
