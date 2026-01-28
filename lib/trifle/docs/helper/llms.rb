# frozen_string_literal: true

module Trifle
  module Docs
    module Helper
      module Llms
        module_function

        def homepage_markdown(config: nil, base_url: '')
          base_url = normalize_base_url(base_url)
          meta = Trifle::Docs.meta(url: base_url, config: config)
          return nil if meta.nil?

          Trifle::Docs::Helper::MarkdownLayout.render(
            meta: meta,
            raw_content: Trifle::Docs.raw_content(url: base_url, config: config)
          )
        end

        def full_markdown(config: nil, base_url: '')
          pages = llms_pages(config: config, base_url: base_url)
          return nil if pages.nil?

          pages.filter_map { |page| render_llms_page(page, config: config) }
               .join("\n\n")
        end

        def llms_pages(config:, base_url:)
          base_url = normalize_base_url(base_url)
          sitemap = Trifle::Docs.sitemap(config: config)
          scoped_sitemap = sitemap_subtree(sitemap, base_url)
          return nil if scoped_sitemap.nil?

          path = base_url.empty? ? [] : base_url.split('/')
          flatten_sitemap(scoped_sitemap, path)
        end

        def render_llms_page(page, config:)
          meta = page[:meta]
          return nil if meta.nil? || meta['type'] == 'file'

          raw = Trifle::Docs.raw_content(url: page[:url], config: config)
          return nil if raw.nil? || raw.strip.empty?

          format_page(meta: meta, url: page[:url], raw_content: raw)
        end

        def sitemap_subtree(sitemap, base_url)
          return nil unless sitemap.is_a?(Hash)

          base_url = normalize_base_url(base_url)
          return sitemap if base_url.empty?

          sitemap.dig(*base_url.split('/'))
        end

        def normalize_base_url(base_url)
          base_url.to_s.gsub(%r{^/+}, '').gsub(%r{/+$}, '')
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
          lines = page_header(meta: meta, url: url)
          lines << raw_content.to_s.strip
          lines << ''
          lines << '---'

          lines.join("\n")
        end

        def page_header(meta:, url:)
          title = meta['title'] || Trifle::Docs::Helper::MarkdownLayout.derive_title_from_url(url)
          page_url = meta['url'] || "/#{url}"

          [
            "# #{title}",
            '',
            "Source: #{page_url}",
            ''
          ]
        end
      end
    end
  end
end
