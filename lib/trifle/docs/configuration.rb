# frozen_string_literal: true

module Trifle
  module Docs
    class Configuration
      attr_accessor :path, :templates

      def initialize
        @harvesters = []
        @path = nil
      end

      def harvester
        @harvester ||= Trifle::Docs::Harvester::Walker.new(
          path: path,
          harvesters: @harvesters
        )
      end

      def register_harvester(harvester)
        @harvesters << harvester
      end
    end
  end
end
