# frozen_string_literal: true

require 'yaml'
require 'redcarpet'

module Trifle
  module Docs
    module Harvester
      module Markdown
        class Sieve < Harvester::Sieve
          def match?
            file.end_with?('.md')
          end

          def to_url
            file.gsub(%r{^#{path}/}, '')
                .gsub(%r{/?index\.md}, '')
                .gsub(/\.md/, '')
          end
        end

        class Conveyor < Harvester::Conveyor
          def content
            @content ||= Redcarpet::Markdown.new(
              Redcarpet::Render::HTML.new(with_toc_data: true)
            ).render(data.gsub(/^---(.*?)---(\s*)/m, ''))
          end

          def meta
            @meta ||= YAML.load_file(file).merge(
              'url' => "/#{url}",
              'breadcrumbs' => url.split('/'),
              'toc' => toc
            )
          end

          def toc
            @toc ||= Redcarpet::Markdown.new(
              Redcarpet::Render::HTML_TOC
            ).render(data.gsub(/^---(.*?)---(\s*)/m, ''))
          end
        end
      end
    end
  end
end
