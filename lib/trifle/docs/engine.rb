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
            get 'llms.txt', to: 'page#llms'
            get 'llms-full.txt', to: 'page#llms_full'
            get '*path/llms.txt', to: 'page#llms'
            get '*path/llms-full.txt', to: 'page#llms_full'
            get 'sitemap.xml', to: 'page#sitemap'
            get 'search', to: 'page#search'
            get '*url', to: 'page#show'
          end
        end
      end

      module PageControllerHelpers
        private

        def render_llms(url, allow_empty: false)
          meta = Trifle::Docs.meta(url: url, config: configuration)
          return send_file(meta['path']) if meta && meta['type'] == 'file'

          content = yield
          return render_not_found if content.nil?
          return render_not_found if !allow_empty && content.strip.empty?

          render plain: content, content_type: 'text/plain'
        end

        def render_sitemap(url)
          meta = Trifle::Docs.meta(url: url, config: configuration)
          return send_file(meta['path']) if meta && meta['type'] == 'file'

          content = yield
          return render_not_found if content.nil? || content.strip.empty?

          render plain: content, content_type: 'application/xml'
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

        def render_markdown(url:, meta:)
          render plain: Trifle::Docs::Helper::MarkdownLayout.render(
            meta: meta,
            raw_content: Trifle::Docs.raw_content(url: url, config: configuration)
          ), content_type: markdown_content_type
        end

        def fetch_meta(url)
          Trifle::Docs.meta(url: url, config: configuration)
        end

        def render_for_meta(meta, url, wants_md, request)
          set_vary_header unless file_meta?(meta)
          return render_markdown(url: url, meta: meta) if render_markdown?(meta, wants_md, request)
          return render_file(meta: meta) if file_meta?(meta)

          render_content(url: url, meta: meta)
        end

        def file_meta?(meta)
          meta['type'] == 'file'
        end

        def resolve_url(params)
          raw_url = params[:url]
          format = params[:format]
          wants_md = markdown_requested?(format, request)
          url = wants_md ? raw_url : [raw_url, format].compact.join('.')
          [url, wants_md]
        end

        def llms_scope
          params[:path].to_s.gsub(%r{^/+}, '').gsub(%r{/+$}, '')
        end

        def render_markdown?(meta, wants_md, request)
          return false if meta['type'] == 'file'

          wants_md || Trifle::Docs::Helper::AiDetection.ai_scraper?(request.user_agent)
        end

        def markdown_requested?(format, request)
          return true if format.to_s.downcase == 'md'

          request.headers['Accept'].to_s.include?('text/markdown')
        end

        def markdown_content_type
          return 'text/plain' if Trifle::Docs::Helper::AiDetection.ai_scraper?(request.user_agent)

          'text/markdown'
        end

        def set_vary_header
          response.headers['Vary'] = append_vary(response.headers['Vary'], 'User-Agent')
          response.headers['Vary'] = append_vary(response.headers['Vary'], 'Accept')
        end

        def append_vary(existing, value)
          values = existing.to_s.split(',').map(&:strip).reject(&:empty?)
          return value if values.empty?
          return existing if values.any? { |entry| entry.casecmp(value).zero? }

          (values + [value]).join(', ')
        end
      end

      class PageController < ActionController::Base
        include PageControllerHelpers

        layout :docs_layout

        def configuration
          params[:configuration] || Trifle::Docs.default
        end

        def docs_layout
          "layouts/trifle/docs/#{configuration.layout}"
        end

        def show
          url, wants_md = resolve_url(params)
          meta = fetch_meta(url)
          return render_not_found if meta.nil?

          render_for_meta(meta, url, wants_md, request)
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

        def llms
          base_url = llms_scope
          llms_url = [base_url, 'llms.txt'].reject(&:empty?).join('/')
          render_llms(llms_url, allow_empty: true) do
            Trifle::Docs::Helper::Llms.homepage_markdown(
              config: configuration,
              base_url: base_url
            )
          end
        end

        def llms_full
          base_url = llms_scope
          llms_url = [base_url, 'llms-full.txt'].reject(&:empty?).join('/')
          render_llms(llms_url) do
            Trifle::Docs::Helper::Llms.full_markdown(
              config: configuration,
              base_url: base_url
            )
          end
        end

        def sitemap
          base_url = configuration.sitemap_base_url || request.base_url
          render_sitemap('sitemap.xml') do
            Trifle::Docs::Helper::Sitemap.xml(config: configuration, base_url: base_url)
          end
        end
      end
    end
  end
end
