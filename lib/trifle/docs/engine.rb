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
            get 'search', to: 'page#search'
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
          render_not_found and return if meta.nil?

          if Trifle::Docs::Helper::AiDetection.ai_scraper?(request.user_agent) && meta['type'] != 'file'
            render plain: Trifle::Docs::Helper::MarkdownLayout.render(
              meta: meta,
              raw_content: Trifle::Docs.raw_content(url: url, config: configuration),
              sitemap: Trifle::Docs.sitemap(config: configuration)
            ), content_type: 'text/markdown'
            return
          end
          render_file(meta: meta) and return if meta['type'] == 'file'

          render_content(url: url, meta: meta)
        end

        def search
          results = Trifle::Docs.search(query: params[:query], scope: params[:scope])

          render 'search', locals: {
            results: results,
            query: params[:query],
            scope: params[:scope],
            sitemap: Trifle::Docs.sitemap,
            meta: { description: 'Search' }
          }
        end

        def render_not_found
          render text: 'Not Found', status: 404
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
