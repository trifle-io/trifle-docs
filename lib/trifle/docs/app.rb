# frozen_string_literal: true

require 'sinatra/base'

module Trifle
  module Docs
    class App < Sinatra::Base
      configure do
        set :bind, '0.0.0.0'
        set :views, proc { Trifle::Docs.default.views }
      end

      get '/search' do
        results = Trifle::Docs.search(query: params['query'], scope: params['scope'])
        erb(
          'search'.to_sym,
          {},
          {
            results: results,
            query: params['query'],
            scope: params['scope'],
            sitemap: Trifle::Docs.sitemap,
            meta: { description: 'Search' }
          }
        )
      end

      get '/llms.txt' do
        meta = Trifle::Docs.meta(url: 'llms.txt')
        return send_file(meta['path']) if meta && meta['type'] == 'file'

        content = Trifle::Docs::Helper::Llms.homepage_markdown
        halt(404, 'Not Found') if content.nil?

        content_type 'text/plain'
        content
      end

      get '/llms-full.txt' do
        meta = Trifle::Docs.meta(url: 'llms-full.txt')
        return send_file(meta['path']) if meta && meta['type'] == 'file'

        content = Trifle::Docs::Helper::Llms.full_markdown
        halt(404, 'Not Found') if content.nil? || content.strip.empty?

        content_type 'text/plain'
        content
      end

      get '/sitemap.xml' do
        meta = Trifle::Docs.meta(url: 'sitemap.xml')
        return send_file(meta['path']) if meta && meta['type'] == 'file'

        render_generated_sitemap
      end

      get '/*' do
        handle_request(params, request)
      end

      def markdown_requested?(request, params)
        return true if params['format'].to_s.downcase == 'md'

        accept = request.env['HTTP_ACCEPT'].to_s
        accept.include?('text/markdown')
      end

      def render_markdown?(meta, request, params)
        return false if meta['type'] == 'file'

        markdown_requested?(request, params) ||
          Trifle::Docs::Helper::AiDetection.ai_scraper?(request.user_agent)
      end

      def handle_request(params, request)
        url = params['splat'].first.chomp('/')
        meta = Trifle::Docs.meta(url: url)
        halt(404, 'Not Found') if meta.nil?

        set_vary_header unless meta['type'] == 'file'
        return render_markdown(meta, url) if render_markdown?(meta, request, params)
        return send_file(meta['path']) if meta['type'] == 'file'

        render_html(meta, url)
      end

      def render_markdown(meta, url)
        content_type markdown_content_type(request)
        Trifle::Docs::Helper::MarkdownLayout.render(
          meta: meta,
          raw_content: Trifle::Docs.raw_content(url: url),
          sitemap: Trifle::Docs.sitemap
        )
      end

      def render_html(meta, url)
        erb (meta['template'] || 'page').to_sym, {}, {
          sitemap: Trifle::Docs.sitemap,
          collection: Trifle::Docs.collection(url: url),
          content: Trifle::Docs.content(url: url),
          meta: meta,
          url: url
        }
      end

      def render_generated_sitemap
        content = Trifle::Docs::Helper::Sitemap.xml
        halt(404, 'Not Found') if content.nil? || content.strip.empty?

        content_type 'application/xml'
        content
      end

      def markdown_content_type(request)
        return 'text/plain' if Trifle::Docs::Helper::AiDetection.ai_scraper?(request.user_agent)

        'text/markdown'
      end

      def set_vary_header
        headers['Vary'] = append_vary(headers['Vary'], 'User-Agent')
        headers['Vary'] = append_vary(headers['Vary'], 'Accept')
      end

      def append_vary(existing, value)
        values = existing.to_s.split(',').map(&:strip).reject(&:empty?)
        return value if values.empty?
        return existing if values.any? { |entry| entry.casecmp(value).zero? }

        (values + [value]).join(', ')
      end

      private :handle_request
    end
  end
end
