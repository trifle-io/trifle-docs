# frozen_string_literal: true

module Trifle
  module Docs
    module Helper
      module Llms
        module_function

        def homepage_markdown(config: nil)
          meta = Trifle::Docs.meta(url: '', config: config)
          return nil if meta.nil?

          Trifle::Docs::Helper::MarkdownLayout.render(
            meta: meta,
            raw_content: Trifle::Docs.raw_content(url: '', config: config),
            sitemap: Trifle::Docs.sitemap(config: config)
          )
        end

        def full_markdown(config: nil)
          sitemap = Trifle::Docs.sitemap(config: config)
          pages = flatten_sitemap(sitemap)

          chunks = pages.filter_map do |page|
            meta = page[:meta]
            next if meta.nil? || meta['type'] == 'file'

            raw = Trifle::Docs.raw_content(url: page[:url], config: config)
            next if raw.nil? || raw.strip.empty?

            format_page(meta: meta, url: page[:url], raw_content: raw)
          end

          chunks.join("\n\n")
        end

        def flatten_sitemap(node, path = [])
          return [] unless node.is_a?(Hash)

          entries = []
          meta = node['_meta']
          entries << { url: path.join('/'), meta: meta } if meta

          node.keys.reject { |key| key == '_meta' }.sort.each do |key|
            entries.concat(flatten_sitemap(node[key], path + [key]))
          end

          entries
        end

        def format_page(meta:, url:, raw_content:)
          title = meta['title'] || Trifle::Docs::Helper::MarkdownLayout.derive_title_from_url(url)
          page_url = meta['url'] || "/#{url}"

          lines = []
          lines << "# #{title}"
          lines << ''
          lines << "Source: #{page_url}"
          lines << ''
          lines << raw_content.to_s.strip
          lines << ''
          lines << '---'

          lines.join("\n")
        end
      end
    end
  end
end
