# frozen_string_literal: true

require_relative 'docs/configuration'
require_relative 'docs/helper/tree'
require_relative 'docs/harvester'
require_relative 'docs/harvester/file'
require_relative 'docs/harvester/markdown'
require_relative 'docs/operations/content'
require_relative 'docs/operations/toc'
require_relative 'docs/operations/collection'
require_relative 'docs/operations/meta'
require_relative 'docs/operations/sitemap'
require_relative 'docs/version'
require_relative 'docs/app' # NOTE: Load app last

module Trifle
  module Docs
    class Error < StandardError; end

    def self.default
      @default ||= Configuration.new
    end

    def self.configure
      yield(default)

      default
    end

    def self.content(url:, config: nil)
      Trifle::Docs::Operations::Content.new(
        url: url, config: config
      ).perform
    end

    def self.meta(url:, config: nil)
      Trifle::Docs::Operations::Meta.new(
        url: url, config: config
      ).perform
    end

    def self.collection(url:, config: nil)
      Trifle::Docs::Operations::Collection.new(
        url: url, config: config
      ).perform
    end

    def self.sitemap(config: nil)
      Trifle::Docs::Operations::Sitemap.new(
        config: config
      ).perform
    end
  end
end
