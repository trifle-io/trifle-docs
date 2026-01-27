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

        content_type 'text/markdown'
        content
      end

      get '/llms-full.txt' do
        meta = Trifle::Docs.meta(url: 'llms-full.txt')
        return send_file(meta['path']) if meta && meta['type'] == 'file'

        content = Trifle::Docs::Helper::Llms.full_markdown
        halt(404, 'Not Found') if content.nil? || content.strip.empty?

        content_type 'text/markdown'
        content
      end

      get '/*' do
        url = params['splat'].first.chomp('/')
        meta = Trifle::Docs.meta(url: url)
        halt(404, 'Not Found') if meta.nil?

        if Trifle::Docs::Helper::AiDetection.ai_scraper?(request.user_agent) && meta['type'] != 'file'
          content_type 'text/markdown'
          return Trifle::Docs::Helper::MarkdownLayout.render(
            meta: meta,
            raw_content: Trifle::Docs.raw_content(url: url),
            sitemap: Trifle::Docs.sitemap
          )
        end

        if meta['type'] == 'file'
          send_file meta['path']
        else
          erb (meta['template'] || 'page').to_sym, {}, {
            sitemap: Trifle::Docs.sitemap,
            collection: Trifle::Docs.collection(url: url),
            content: Trifle::Docs.content(url: url),
            meta: meta,
            url: url
          }
        end
      end
    end
  end
end
