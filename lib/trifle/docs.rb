# frozen_string_literal: true

require_relative 'docs/configuration'
require_relative 'docs/helper/routing'
require_relative 'docs/harvester/markdown'
require_relative 'docs/operations/page/find'
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
      Trifle::Docs::Operations::Page::Find.new(
        url: url, config: config
      ).perform
    end

    # def self.menu(for:, config: nil)
    #   "Trifle::Docs::Operations::Menu::#{for.classify}".constantize.new(
    #     config: nil
    #   ).perform
    # end
  end
end

# Trifle::Docs.configure do |config|
#   config.harvester = Trifle::Docs::Harvester::Markdown.new(path: 'docs')
# end
# Trifle::Docs.page()
