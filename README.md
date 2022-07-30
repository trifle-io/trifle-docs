# Trifle::Docs

[![Gem Version](https://badge.fury.io/rb/trifle-docs.svg)](https://badge.fury.io/rb/trifle-docs)
![Ruby](https://github.com/trifle-io/trifle-docs/workflows/Ruby/badge.svg?branch=main)
[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/trifle-io/trifle-docs)

Simple documentation backend for your markdown files.

Integrate your documentation or blog into your existing Rails application. `Trifle::Docs` maps your docs folder full of markdown files to your URLs and allows you to integrate it with same layout as the rest of your app.

![Demo App](demo.gif)


## Documentation

You can find guides and documentation at https://trifle.io/trifle-docs

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
$ bundle add trifle-docs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
$ gem install trifle-docs
```

## Usage

You can use this as a build-in Sinatra app or mount it in your Rails app. For each usecse, refere to documentation. Below is sample Sinatra integration.

```ruby
# app.rb
require 'trifle/docs'

Trifle::Docs.configure do |config|
  config.path = 'docs'
  config.templates = File.join(__dir__, '..', 'templates', 'simple')
  config.register_harvester(Trifle::Docs::Harvester::Markdown)
  config.register_harvester(Trifle::Docs::Harvester::File)
end

Trifle::Docs.App.run!
```

### Templates

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

### Template variables

There are several variables available in your template file (except `layout.erb`).
- `sitemap` - complete sitemap tree of the folder.
- `collection` - current subtree of the folder (useful for rendering child content, aka collection).
- `content` - rendered markdown file.
- `meta` - metadata from markdown file.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

You can test the sinatra app by running `bin/docs` that uses `templates/simple` templates to render `docs` files.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trifle-io/trifle-docs. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/trifle-io/trifle-docs/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Trifle::Docs project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/trifle-io/trifle-docs/blob/master/CODE_OF_CONDUCT.md).
