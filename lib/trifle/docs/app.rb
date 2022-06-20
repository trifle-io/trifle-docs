# frozen_string_literal: true

require 'sinatra/base'

module Trifle
  module Docs
    class App < Sinatra::Base
      configure do
        set :bind, '0.0.0.0'
        set :config, (Trifle::Docs::Configuration.new.tap do |config|
          config.harvester = Trifle::Docs::Harvester::Markdown.new(path: 'docs')
        end)
      end

      get '/*' do
        Trifle::Docs.page(url: params['splat'].first, config: settings.config)
      end
    end
  end
end
