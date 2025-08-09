# frozen_string_literal: true

module Trifle
  module Docs
    module Harvester
      class Walker # rubocop:disable Metrics/ClassLength
        attr_reader :path, :router, :namespace, :cache

        def initialize(**keywords)
          @path = keywords.fetch(:path)
          @harvesters = keywords.fetch(:harvesters)
          @namespace = keywords.fetch(:namespace)
          @cache = keywords.fetch(:cache)
          @router = {}

          gather
        end

        def gather # rubocop:disable Metrics/MethodLength
          Dir["#{path}/**/*.*"].each do |file|
            @harvesters.each do |harvester|
              sieve = harvester::Sieve.new(path: path, file: file)
              next unless sieve.match?

              @router[sieve.to_url] = harvester::Conveyor.new(
                file: file, url: sieve.to_url, namespace: namespace, cache: cache
              )
              break
            end
          end
          true
        end

        def sitemap
          @sitemap ||= begin
            mapping = router.keys.each_with_object({}) do |url, out|
              out[url] = meta_for(url: url)
            end

            Trifle::Docs::Helper::Tree.new(mapping: mapping).menu
          end
        end

        def search_for(query:, limit: 10) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
          return [] if query.nil? || query.strip.empty?

          query_terms = query.downcase.split(/\s+/)
          matches = []

          router.each do |url, conveyor|
            score = calculate_match_score(conveyor, query_terms)
            next if score.zero?

            matches << {
              url: url,
              conveyor: conveyor,
              score: score
            }

            break if matches.size >= limit * 2
          end

          matches.sort_by { |match| -match[:score] }
                 .first(limit)
                 .map { |match| build_search_result(match, query_terms) }
        end

        def collection_for(url:)
          return sitemap if url.empty?

          sitemap.dig(*url.split('/'))
        end

        def content_for(url:)
          route_for(url: url)&.content
        end

        def meta_for(url:)
          route_for(url: url)&.meta
        end

        def route_for(url:)
          @router[url] || not_found(url: url)
        end

        def not_found(url:)
          puts "No route found for url: #{url}"
        end

        private

        def calculate_match_score(conveyor, query_terms) # rubocop:disable Metrics/AbcSize
          score = 0

          searchable_content = extract_searchable_content(conveyor)

          query_terms.each do |term|
            score += search_in_field(searchable_content[:title], term, weight: 10)
            score += search_in_field(searchable_content[:url], term, weight: 8)
            score += search_in_field(searchable_content[:tags], term, weight: 7)
            score += search_in_field(searchable_content[:content], term, weight: 1)
            score += search_in_field(searchable_content[:meta], term, weight: 5)
          end

          score
        end

        def extract_searchable_content(conveyor) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
          content = {}

          content[:url] = conveyor.url.downcase

          if conveyor.respond_to?(:content) && conveyor.cache
            content[:content] = strip_html(conveyor.content || '').downcase
          end

          if conveyor.respond_to?(:meta) && conveyor.cache
            meta = conveyor.meta || {}
            content[:title] = (meta['title'] || '').downcase
            content[:meta] = meta.values.join(' ').downcase

            # Include tags as searchable content
            tags = extract_tags(conveyor)
            content[:tags] = tags.join(' ').downcase
          end

          content
        end

        def search_in_field(field_content, term, weight:)
          return 0 if field_content.nil? || field_content.empty?

          occurrences = field_content.scan(/#{Regexp.escape(term)}/i).size
          occurrences * weight
        end

        def build_search_result(match, query_terms) # rubocop:disable Metrics/MethodLength
          conveyor = match[:conveyor]
          title = extract_title(conveyor)
          excerpt = generate_excerpt(conveyor, query_terms)
          tags = extract_tags(conveyor)

          {
            url: match[:url],
            title: title,
            excerpt: excerpt,
            tags: tags,
            score: match[:score]
          }
        end

        def extract_title(conveyor) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          if conveyor.respond_to?(:meta) && conveyor.cache
            meta = conveyor.meta || {}
            title = meta['title']
            return title unless title.nil? || title.strip.empty?
          end

          conveyor.url.split('/').last&.gsub(/[-_]/, ' ')&.split&.map(&:capitalize)&.join(' ') || 'Untitled'
        end

        def extract_tags(conveyor) # rubocop:disable Metrics/MethodLength
          return [] unless conveyor.respond_to?(:meta) && conveyor.cache

          meta = conveyor.meta || {}
          tags = meta['tags']

          case tags
          when Array
            tags.compact.map(&:to_s)
          when String
            [tags]
          else
            []
          end
        end

        def generate_excerpt(conveyor, query_terms, max_length: 200)
          return nil unless conveyor.respond_to?(:content) && conveyor.cache

          content = strip_html(conveyor.content || '')
          return nil if content.empty?

          best_excerpt = find_best_excerpt(content, query_terms, max_length)
          best_excerpt || content[0, max_length] + (content.length > max_length ? '...' : '')
        end

        def find_best_excerpt(content, query_terms, max_length) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
          return nil if query_terms.empty?

          first_match_pos = nil
          matched_term = nil

          query_terms.each do |term|
            pos = content.downcase.index(term.downcase)
            if pos && (first_match_pos.nil? || pos < first_match_pos)
              first_match_pos = pos
              matched_term = term
            end
          end

          return nil unless first_match_pos

          context_size = (max_length - matched_term.length) / 2
          start_pos = [first_match_pos - context_size, 0].max
          end_pos = [start_pos + max_length, content.length].min

          start_pos = find_word_boundary(content, start_pos, :backward)
          end_pos = find_word_boundary(content, end_pos, :forward)

          excerpt = content[start_pos...end_pos]

          excerpt = "...#{excerpt}" if start_pos.positive?
          excerpt += '...' if end_pos < content.length

          excerpt
        end

        def find_word_boundary(content, pos, direction) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          return pos if pos <= 0 || pos >= content.length

          if direction == :backward
            pos -= 1 while pos.positive? && !content[pos].match?(/\s/)
            pos += 1 if content[pos].match?(/\s/)
          else # :forward
            pos += 1 while pos < content.length && !content[pos].match?(/\s/)
          end

          pos
        end

        def strip_html(html)
          return '' if html.nil?

          # Ensure valid UTF-8 encoding
          html = html.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
          html.gsub(/<[^>]*>/, ' ').gsub(/\s+/, ' ').strip
        end
      end

      class Sieve
        attr_reader :path, :file

        def initialize(path:, file:)
          @path = path
          @file = file
        end

        def match?
          raise 'Not Impelemented'
        end

        def to_url
          raise 'Not Impelemented'
        end
      end

      class Conveyor
        attr_reader :file, :url, :namespace, :cache

        def initialize(file:, url:, namespace:, cache:)
          @file = file
          @url = url
          @namespace = namespace
          @cache = cache

          preload_cache if cache
        end

        def preload_cache
          # NOTE: harvester is responsible for cache implementation
        end

        def data
          @data = nil unless cache

          @data ||= ::File.read(file, encoding: 'utf-8')
        end
      end
    end
  end
end
