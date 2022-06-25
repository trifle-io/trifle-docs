# frozen_string_literal: true

module Trifle
  module Docs
    module Harvester
      class Walker
        attr_reader :path, :router

        def initialize(**keywords)
          @path = keywords.fetch(:path)
          @harvesters = keywords.fetch(:harvesters)
          @router = {}

          gather
        end

        def gather
          Dir["#{path}/**/*.*"].each do |file|
            @harvesters.each do |harvester|
              sieve = harvester::Sieve.new(path: path, file: file)
              if sieve.match?
                @router[sieve.to_url] = harvester::Conveyor.new(file: file, url: sieve.to_url)
                break
              end
            end
          end
          true
        end

        def sitemap
          @sitemap ||= begin
            mapping = router.keys.each_with_object({}) do |url, out|
              out[url] = meta_for(url: url)
            end

            Trifle::Docs::Helper::Tree.new(mapping: mapping).menu
          end
        end

        def collection_for(url:)
          return sitemap if url.empty?

          sitemap.dig(*url.split('/'))
        end

        def content_for(url:)
          @router[url].content
        end

        def meta_for(url:)
          @router[url].meta
        end
      end

      class Sieve
        attr_reader :path, :file

        def initialize(path:, file:)
          @path = path
          @file = file
        end

        def match?
          raise 'Not Impelemented'
        end

        def to_url
          raise 'Not Impelemented'
        end
      end

      class Conveyor
        attr_reader :file, :url

        def initialize(file:, url:)
          @file = file
          @url = url
        end

        def data
          @data ||= ::File.read(file)
        end
      end
    end
  end
end
