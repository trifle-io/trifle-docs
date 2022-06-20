# frozen_string_literal: true

module Trifle
  module Docs
    module Helper
      class Routing
        attr_reader :path, :file

        def initialize(path:, file:)
          @path = path
          @file = file
        end

        def to_collection
          file.gsub(%r{^#{path}/collections/}, '').split('/').first
        end

        def to_url
          file.gsub(%r{^#{path}/pages/}, '')
              .gsub(%r{^#{path}/collections/}, '')
              .gsub(%r{/?index\.md}, '')
              .gsub(/\.md/, '')
        end
      end
    end
  end
end
