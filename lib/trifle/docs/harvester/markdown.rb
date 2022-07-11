# frozen_string_literal: true

require 'yaml'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

module Trifle
  module Docs
    module Harvester
      module Markdown
        class Render < Redcarpet::Render::HTML
          include Rouge::Plugins::Redcarpet
        end

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
              Render.new(with_toc_data: true),
              fenced_code_blocks: true,
              disable_indented_code_blocks: true,
              footnotes: true
            ).render(data.sub(/^---(.*?)---(\s*)/m, ''))
          end

          def meta
            @meta ||= (YAML.safe_load(data[/^---(.*?)---(\s*)/m].to_s) || {}).merge(
              'url' => "/#{[namespace, url].compact.join('/')}",
              'breadcrumbs' => url.split('/'),
              'toc' => toc,
              'updated_at' => ::File.stat(file).mtime
            )
          end

          def toc
            @toc ||= Redcarpet::Markdown.new(
              Redcarpet::Render::HTML_TOC
            ).render(data.sub(/^---(.*?)---(\s*)/m, ''))
          end
        end
      end
    end
  end
end
