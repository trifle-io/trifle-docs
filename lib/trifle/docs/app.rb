# frozen_string_literal: true

require 'sinatra/base'

module Trifle
  module Docs
    class App < Sinatra::Base
      configure do
        set :bind, '0.0.0.0'
        set :views, proc { Trifle::Docs.default.views }
      end

      get '/*' do
        url = params['splat'].first.chomp('/')
        meta = Trifle::Docs.meta(url: url)
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
