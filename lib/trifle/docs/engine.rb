# frozen_string_literal: true

if Object.const_defined?('Rails')
  module Trifle
    module Docs
      class Engine < ::Rails::Engine
        isolate_namespace Trifle::Docs

        def self.mount(router, namespace:)
          configuration = Configuration.new
          configuration.namespace = namespace
          yield(configuration)

          router.mount self => "/#{namespace}", as: namespace, configuration: configuration
        end

        def self.draw
          Trifle::Docs::Engine.routes.draw do
            root to: 'page#show'
            get '*url', to: 'page#show'
          end
        end
      end

      class PageController < ActionController::Base
        layout :docs_layout

        def configuration
          params[:configuration] || Trifle::Docs.default
        end

        def docs_layout
          "layouts/trifle/docs/#{configuration.layout}"
        end

        def show
          url = [params[:url], params[:format]].compact.join('.')
          meta = Trifle::Docs.meta(url: url, config: configuration)
          render_file(meta: meta) and return if meta['type'] == 'file'

          render_content(url: url, meta: meta)
        end

        def render_file(meta:)
          send_file(meta['path'])
        end

        def render_content(url:, meta:)
          render (meta['template'] || 'page'), locals: {
            sitemap: Trifle::Docs.sitemap(config: configuration),
            collection: Trifle::Docs.collection(url: url, config: configuration),
            content: Trifle::Docs.content(url: url, config: configuration),
            meta: meta,
            url: url
          }
        end
      end
    end
  end
end
