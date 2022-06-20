# frozen_string_literal: true

require 'yaml'
require 'redcarpet'
require_relative '../helper/routing'

module Trifle
  module Docs
    module Harvester
      class Markdown
        attr_reader :path, :mapping, :collections

        def initialize(**keywords)
          @path = keywords.fetch(:path)
          @mapping = {}
          @collections = Hash.new { |h, k| h[k] = [] }

          gather
        end

        def gather
          Dir["#{path}/**/*.md"].each do |file|
            routing = Trifle::Docs::Helper::Routing.new(path: path, file: file)
            @mapping[routing.to_url] = file
            next unless file.start_with?("#{path}/collections")

            @collections[routing.to_collection] << YAML.load_file(file).merge(
              'url' => routing.to_url
            )
          end
          true
        end

        def metadata_for(url: nil, file: nil)
          return nil if url.nil? && file.nil?

          YAML.load_file(file || mapping[url])
        end

        def content_for(url: nil, file: nil)
          return nil if url.nil? && file.nil?

          markdown.render(read(file: file || mapping[url]))
        end

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
