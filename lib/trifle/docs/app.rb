# frozen_string_literal: true

require 'sinatra/base'

module Trifle
  module Docs
    module AppHelpers
      def markdown_requested?(request, params)
        return true if params['format'].to_s.downcase == 'md'

        request.env['HTTP_ACCEPT'].to_s.include?('text/markdown')
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

        set_vary_header unless file_meta?(meta)
        return render_markdown(meta, url) if render_markdown?(meta, request, params)
        return send_file(meta['path']) if file_meta?(meta)

        render_html(meta, url)
      end

      def render_markdown(meta, url)
        content_type markdown_content_type(request)
        Trifle::Docs::Helper::MarkdownLayout.render(
          meta: meta,
          raw_content: Trifle::Docs.raw_content(url: url)
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

      def render_llms_for(base_url, full:)
        base_url = normalize_base_url(base_url)
        url = llms_url(base_url, full: full)
        meta = Trifle::Docs.meta(url: url)
        return send_file(meta['path']) if file_meta?(meta)

        content = llms_content(full: full, base_url: base_url)
        halt(404, 'Not Found') if llms_missing?(content, full: full)

        content_type 'text/plain'
        content
      end

      private

      def append_vary(existing, value)
        values = existing.to_s.split(',').map(&:strip).reject(&:empty?)
        return value if values.empty?
        return existing if values.any? { |entry| entry.casecmp(value).zero? }

        (values + [value]).join(', ')
      end

      def normalize_base_url(base_url)
        base_url.to_s.gsub(%r{^/+}, '').gsub(%r{/+$}, '')
      end

      def llms_url(base_url, full:)
        llms_name = full ? 'llms-full.txt' : 'llms.txt'
        [base_url, llms_name].reject(&:empty?).join('/')
      end

      def llms_content(full:, base_url:)
        if full
          Trifle::Docs::Helper::Llms.full_markdown(base_url: base_url)
        else
          Trifle::Docs::Helper::Llms.homepage_markdown(base_url: base_url)
        end
      end

      def llms_missing?(content, full:)
        return true if content.nil?
        return false unless full

        content.strip.empty?
      end

      def file_meta?(meta)
        meta && meta['type'] == 'file'
      end
    end

    class App < Sinatra::Base
      configure do
        set :bind, '0.0.0.0'
        set :views, proc { Trifle::Docs.default.views }
      end

      helpers AppHelpers

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
        render_llms_for('', full: false)
      end

      get %r{/(.+)/llms\.txt} do |path|
        render_llms_for(path, full: false)
      end

      get '/llms-full.txt' do
        render_llms_for('', full: true)
      end

      get %r{/(.+)/llms-full\.txt} do |path|
        render_llms_for(path, full: true)
      end

      get '/sitemap.xml' do
        meta = Trifle::Docs.meta(url: 'sitemap.xml')
        return send_file(meta['path']) if meta && meta['type'] == 'file'

        render_generated_sitemap
      end

      get '/*' do
        handle_request(params, request)
      end
    end
  end
end
