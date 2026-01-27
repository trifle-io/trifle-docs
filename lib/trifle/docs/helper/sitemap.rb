# frozen_string_literal: true

require 'cgi'
require 'time'

module Trifle
  module Docs
    module Helper
      module Sitemap
        module_function

        def xml(config: nil)
          sitemap = Trifle::Docs.sitemap(config: config)
          urls = sitemap_urls(sitemap)
          return nil if urls.empty?

          build_document(urls)
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

        def sitemap_urls(sitemap)
          entries = flatten_sitemap(sitemap)
          entries.filter_map do |entry|
            meta = entry[:meta]
            next if meta.nil? || meta['type'] == 'file'

            build_url_entry(entry[:url], meta)
          end
        end

        def build_document(urls)
          [
            %(<?xml version="1.0" encoding="UTF-8"?>),
            %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">),
            urls.join("\n"),
            %(</urlset>)
          ].join("\n")
        end

        def build_url_entry(url, meta)
          loc = normalize_loc(url, meta)
          lastmod = format_lastmod(meta['updated_at'])
          lastmod_tag = lastmod ? "<lastmod>#{lastmod}</lastmod>" : ''

          "<url><loc>#{loc}</loc>#{lastmod_tag}</url>"
        end

        def normalize_loc(url, meta)
          loc = meta['url']
          loc = "/#{url}" if loc.nil? || loc.empty?
          loc = '/' if loc == '//'
          CGI.escapeHTML(loc)
        end

        def format_lastmod(value)
          return nil if value.nil?

          return value.utc.iso8601 if value.respond_to?(:utc) && value.respond_to?(:iso8601)
          return value.iso8601 if value.respond_to?(:iso8601)

          nil
        end
      end
    end
  end
end
