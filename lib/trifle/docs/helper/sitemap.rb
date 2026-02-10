# frozen_string_literal: true

require 'cgi'
require 'time'
require 'uri'

module Trifle
  module Docs
    module Helper
      module Sitemap
        module_function

        def xml(config: nil, base_url: nil)
          sitemap = Trifle::Docs.sitemap(config: config)
          resolved_base_url = resolve_base_url(config: config, base_url: base_url)
          urls = sitemap_urls(sitemap, base_url: resolved_base_url)
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

        def sitemap_urls(sitemap, base_url: nil)
          entries = flatten_sitemap(sitemap)
          entries.filter_map do |entry|
            meta = entry[:meta]
            next if meta.nil? || meta['type'] == 'file'

            build_url_entry(entry[:url], meta, base_url: base_url)
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

        def build_url_entry(url, meta, base_url: nil)
          loc = normalize_loc(url, meta, base_url: base_url)
          lastmod = format_lastmod(meta['updated_at'])
          lastmod_tag = lastmod ? "<lastmod>#{lastmod}</lastmod>" : ''

          "<url><loc>#{loc}</loc>#{lastmod_tag}</url>"
        end

        def normalize_loc(url, meta, base_url: nil)
          loc = meta['url']
          loc = "/#{url}" if loc.nil? || loc.empty?
          loc = '/' if loc == '//'
          loc = absolutize_loc(loc, base_url)
          CGI.escapeHTML(loc)
        end

        def absolutize_loc(loc, base_url)
          return loc if base_url.nil? || absolute_url?(loc)

          path = loc.to_s.gsub(%r{^/+}, '')
          return "#{base_url}/" if path.empty?

          "#{base_url}/#{path}"
        end

        def absolute_url?(loc)
          loc.to_s.match?(%r{\Ahttps?://}i)
        end

        def resolve_base_url(config:, base_url:)
          normalize_base_url(base_url) || normalize_base_url(configuration_base_url(config))
        end

        def configuration_base_url(config)
          return nil unless config.respond_to?(:sitemap_base_url)

          config.sitemap_base_url
        end

        def normalize_base_url(base_url)
          value = base_url.to_s.strip
          return nil if value.empty?

          uri = URI.parse(value)
          return nil unless uri.is_a?(URI::HTTP) && uri.host

          uri.query = nil
          uri.fragment = nil
          uri.to_s.gsub(%r{/+$}, '')
        rescue URI::InvalidURIError
          nil
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
