# frozen_string_literal: true

module Trifle
  module Docs
    module Helper
      module MarkdownLayout
        module_function

        def render(meta:, raw_content:, sitemap:) # rubocop:disable Metrics/MethodLength
          lines = []
          title = meta['title'] || derive_title_from_url(meta['url'])

          lines << "# #{title}"
          lines << ''
          lines << '## Navigation'
          lines << navigation_toc(sitemap)
          lines << ''
          lines << '## Content'
          lines << raw_content.to_s.strip
          lines << ''

          lines.join("\n")
        end

        def navigation_toc(sitemap, depth: 0) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          return '' unless sitemap.is_a?(Hash)

          sitemap.keys.reject { |k| k == '_meta' }.sort.map do |key|
            node = sitemap[key]
            meta = node['_meta'] || {}
            title = meta['title'] || derive_title_from_url(meta['url'] || key)
            url = meta['url'] || "/#{key}"
            indent = '  ' * depth
            children = node.reject { |child_key, _| child_key == '_meta' }

            [
              "#{indent}- [#{title}](#{url})",
              navigation_toc(children, depth: depth + 1)
            ].reject(&:empty?).join("\n")
          end.join("\n")
        end

        def derive_title_from_url(url)
          return 'Untitled' if url.nil? || url.empty?

          url.split('/').last.to_s.gsub(/[-_]/, ' ').split.map(&:capitalize).join(' ')
        end
      end
    end
  end
end
