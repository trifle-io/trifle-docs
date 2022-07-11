# frozen_string_literal: true

module Trifle
  module Docs
    module Harvester
      class Walker
        attr_reader :path, :router, :namespace

        def initialize(**keywords)
          @path = keywords.fetch(:path)
          @harvesters = keywords.fetch(:harvesters)
          @namespace = keywords.fetch(:namespace)
          @router = {}

          gather
        end

        def gather
          Dir["#{path}/**/*.*"].each do |file|
            @harvesters.each do |harvester|
              sieve = harvester::Sieve.new(path: path, file: file)
              if sieve.match?
                @router[sieve.to_url] = harvester::Conveyor.new(file: file, url: sieve.to_url, namespace: namespace)
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
          route_for(url: url)&.content
        end

        def meta_for(url:)
          route_for(url: url)&.meta
        end

        def route_for(url:)
          @router[url] ? not_found(url: url) : @router[url]
        end

        def not_found(url:)
          puts "No route found for url: #{url}"
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
        attr_reader :file, :url, :namespace

        def initialize(file:, url:, namespace:)
          @file = file
          @url = url
          @namespace = namespace
        end

        def data
          @data ||= ::File.read(file)
        end
      end
    end
  end
end
