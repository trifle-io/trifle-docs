# frozen_string_literal: true

module Trifle
  module Docs
    class Configuration
      attr_accessor :path, :views, :layout, :namespace, :cache, :sitemap_base_url

      def initialize
        @harvesters = []
        @path = nil
        @namespace = nil
        @cache = true
        @sitemap_base_url = nil
      end

      def harvester
        @harvester ||= Trifle::Docs::Harvester::Walker.new(
          path: path,
          harvesters: @harvesters,
          namespace: namespace,
          cache: cache
        )
      end

      def register_harvester(harvester)
        @harvesters << harvester
      end
    end
  end
end
