# frozen_string_literal: true

require 'yaml'
require 'redcarpet'
require_relative '../helper/routing'

module Trifle
  module Docs
    module Harvester
      class Markdown
        attr_reader :path, :mapping

        def initialize(**keywords)
          @path = keywords.fetch(:path)
          @mapping = {}

          gather
        end

        def gather
          Dir["#{path}/**/*.md"].each do |file|
            routing = Trifle::Docs::Helper::Routing.new(path: path, file: file)
            @mapping[routing.to_url] = file
          end
          true
        end

        def sitemap
          meta_mapping = mapping.keys.each_with_object({}) do |url, out|
            out[url] = meta_for(url: url)
          end

          Trifle::Docs::Helper::Tree.new(mapping: meta_mapping).menu
        end

        def meta_for(url: nil, file: nil)
          return nil if url.nil? && file.nil?

          YAML.load_file(file || mapping[url]).merge(
            'url' => "/#{url}",
            'breadcrumbs' => url.split('/')
          )
        end

        def content_for(url: nil, file: nil)
          return nil if url.nil? && file.nil?

          markdown.render(read(file: file || mapping[url]))
        end

        def collection_for(url:)
          return sitemap if url.empty?

          sitemap.dig(*url.split('/'))
        end

        private

        def read(file:)
          File.read(file).gsub(/^---(.*?)---(\s*)/m, '')
        end

        def markdown
          @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
        end
      end
    end
  end
end
