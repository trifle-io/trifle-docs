# frozen_string_literal: true

require_relative 'docs/configuration'
require_relative 'docs/helper/routing'
require_relative 'docs/helper/tree'
require_relative 'docs/harvester/markdown'
require_relative 'docs/operations/page'
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

    def self.page(url:, config: nil)
      Trifle::Docs::Operations::Page.new(
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

# Trifle::Docs.configure do |config|
#   config.harvester = Trifle::Docs::Harvester::Markdown.new(path: 'docs')
# end
# Trifle::Docs.page()
