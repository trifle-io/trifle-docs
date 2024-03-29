# frozen_string_literal: true

require_relative "lib/trifle/docs/version"

Gem::Specification.new do |spec|
  spec.name = "trifle-docs"
  spec.version = Trifle::Docs::VERSION
  spec.authors = ["Jozef Vaclavik"]
  spec.email = ["jozef@hey.com"]

  spec.summary = "Simple documentation for your markdown files."
  spec.description = "Trifle::Docs is way too simple documentation app. "\
                     'It uses your markdown files and structure to build '\
                     'up your documentation. You can use it as a standalone '\
                     'app or mount it in your Rails app.'
  spec.homepage      = 'https://trifle.io'
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/trifle-io/trifle-docs'
  spec.metadata['changelog_uri'] = 'https://trifle.io/trifle-docs/changelog'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_development_dependency('bundler', '~> 2.1')
  spec.add_development_dependency('byebug', '>= 0')
  spec.add_development_dependency('puma')
  spec.add_development_dependency('rake', '~> 13.0')
  spec.add_development_dependency('rspec', '~> 3.2')
  spec.add_development_dependency('rubocop', '1.0.0')

  spec.add_dependency('redcarpet')
  spec.add_dependency('rouge')
  spec.add_dependency('sinatra')
  spec.add_dependency('yaml')

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
