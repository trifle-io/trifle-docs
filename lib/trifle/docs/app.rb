# frozen_string_literal: true

require 'sinatra/base'

module Trifle
  module Docs
    class App < Sinatra::Base
      configure do
        set :bind, '0.0.0.0'
        set :views, Proc.new { Trifle::Docs.default.templates }
      end

      get '/*' do
        meta = Trifle::Docs.meta(url: params['splat'].first)
        erb (meta['template'] || 'page').to_sym, {}, {
          sitemap: Trifle::Docs.sitemap,
          collection: Trifle::Docs.collection(url: params['splat'].first),
          content: Trifle::Docs.page(url: params['splat'].first),
          meta: meta
        }
      end
    end
  end
end
