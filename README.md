# Trifle::Docs

[![Gem Version](https://badge.fury.io/rb/trifle-docs.svg)](https://rubygems.org/gems/trifle-docs)
[![Ruby](https://github.com/trifle-io/trifle-docs/workflows/Ruby/badge.svg?branch=main)](https://github.com/trifle-io/trifle-docs)

Simple router for your static documentation. Like markdown, or textile, or whatever files. It maps your docs folder structure into URLs and renders them within the simplest template possible.

## Documentation

For comprehensive guides, API reference, and examples, visit [trifle.io/trifle-docs](https://trifle.io/trifle-docs)

![Demo App](demo.gif)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trifle-docs'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install trifle-docs
```

## Quick Start

### 1. Configure

```ruby
require 'trifle/docs'

Trifle::Docs.configure do |config|
  config.path = File.join(__dir__, 'docs')
  config.views = File.join(__dir__, 'templates')
  config.register_harvester(Trifle::Docs::Harvester::Markdown)
  config.register_harvester(Trifle::Docs::Harvester::File)
end
```

### 2. Create documentation structure

```
docs/
├── index.md
├── getting-started/
│   ├── index.md
│   └── installation.md
└── api/
    ├── index.md
    └── reference.md
```

### 3. Use in your application

```ruby
# As Rack middleware
use Trifle::Docs::Middleware

# Or mount in Rails
Rails.application.routes.draw do
  mount Trifle::Docs::Engine => '/docs'
end

# Or Sinatra app
```

### 4. Templates

Please create two files in folder you provided the configuration.

```ruby
# templates/layout.erb
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Trifle::Docs</title>
  </head>
  <body>
    <%= yield %>
  </body>
</html>

# templates/page.erb
<%= content %>
```

#### Template variables

There are several variables available in your template file (except `layout.erb`).
- `sitemap` - complete sitemap tree of the folder.
- `collection` - current subtree of the folder (useful for rendering child content, aka collection).
- `content` - rendered markdown file.
- `meta` - metadata from markdown file.

## Features

- **File-based routing** - Maps folder structure to URL paths
- **Multiple harvesters** - Markdown, textile, and custom file processors
- **Template system** - ERB templates with layout support
- **Flexible integration** - Works with Rack, Rails, Sinatra
- **Caching support** - Optional caching for production environments
- **Navigation helpers** - Automatic menu and breadcrumb generation

## Harvesters

Trifle::Docs supports multiple content processors:

- **Markdown** - Process `.md` files with frontmatter support
- **File** - Handle static assets and non-markdown content
- **Custom** - Build your own harvesters for specialized content

## Testing

Tests focus on documenting behavior and ensuring reliability. To run the test suite:

```bash
$ bundle exec rspec
```

Tests are meant to be **simple and isolated**. Every test should be **independent** and able to run in any order. Tests should be **self-contained** and set up their own configuration.

Use **single layer testing** to focus on testing a specific class or module in isolation. Use **appropriate stubbing** for file system operations when testing harvesters and routing logic.

**Repeat yourself** in test setup for clarity rather than complex shared setups that can hide dependencies.

Tests verify that file system changes are properly reflected in the documentation routing and that templates render correctly with provided content.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trifle-io/trifle-docs.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
