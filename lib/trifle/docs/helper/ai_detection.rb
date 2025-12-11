# frozen_string_literal: true

module Trifle
  module Docs
    module Helper
      module AiDetection
        AI_SCRAPER_PATTERNS = [
          /GPTBot/i,
          /ChatGPT/i,
          /ClaudeBot/i,
          /Claude-Web/i,
          /anthropic/i,
          /Perplexity/i,
          /Google-Extended/i,
          /CCBot/i,
          /AI2Bot/i,
          /FacebookBot/i
        ].freeze

        module_function

        def ai_scraper?(user_agent)
          return false if user_agent.nil? || user_agent.empty?

          AI_SCRAPER_PATTERNS.any? { |pattern| user_agent.match?(pattern) }
        end
      end
    end
  end
end
