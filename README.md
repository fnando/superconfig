![SuperConfig: Access environment variables. Also includes presence validation, type coercion and default values.](https://raw.githubusercontent.com/fnando/superconfig/main/superconfig.png)

<p align="center">
  <a href="https://github.com/fnando/superconfig/actions/workflows/ruby-tests.yml"><img src="https://github.com/fnando/superconfig/workflows/ruby-tests/badge.svg" alt="Github Actions"></a>
  <a href="https://codeclimate.com/github/fnando/superconfig"><img src="https://codeclimate.com/github/fnando/superconfig/badges/gpa.svg" alt="Code Climate"></a>
  <a href="https://rubygems.org/gems/superconfig"><img src="https://img.shields.io/gem/v/superconfig.svg" alt="Gem"></a>
  <a href="https://rubygems.org/gems/superconfig"><img src="https://img.shields.io/gem/dt/superconfig.svg" alt="Gem"></a>
</p>

## Installation

Add this line to your application's Gemfile:

```ruby
gem "superconfig"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install superconfig

## Usage

```ruby
Config = SuperConfig.new do
  mandatory :database_url, string
  optional  :timeout, int, 10
  optional  :force_ssl, bool, false
  optional  :rails_env, "development", string, aliases: %w[env]
end

Config.database_url
Config.timeout
Config.force_ssl?
```

You can specify the description for both `mandatory` and `optional` methods;
this will be used in exceptions.

```ruby
Config = SuperConfig.new do
  mandatory :missing_var, string, description: "this is important"
end

#=> SuperConfig::MissingEnvironmentVariable: MISSING_VAR (this is important) is not defined
```

If you're going to use `SuperConfig` as your main configuration object, you can
also set arbitrary properties, like the following:

```ruby
Config = SuperConfig.new do
  optional :redis_url, string, "redis://127.0.0.1"
  property :redis, -> { Redis.new } # pass an object that responds to #call
  property(:now) { Time.now }       # or pass a block.
end

Config.redis.set("key", "value")
Config.redis.get("key")
#=> "value"
```

Values are cached by default. If you want to dynamically generate new values,
set `cache: false`.

```ruby
Config = SuperConfig.new do
  property(:uuid, cache: false) { SecureRandom.uuid }
end
```

You can also set values using `SuperConfig#set`.

```ruby
Config = SuperConfig.new do
  set :domain, "example.com"
end
```

You may want to start a debug session without raising exceptions for missing
variables. In this case, just pass `raise_exception: false` instead to log error
messages to `$stderr`. This is especially great with Rails' credentials command
(`rails credentials:edit`) when already defined the configuration.

```ruby
Config = SuperConfig.new(raise_exception: false) do
  mandatory :database_url, string, description: "the leader database"
end

#=> [SUPERCONFIG] DATABASE_URL (the leader database) is not defined
```

I'd like to centralize access to my credentials; there's a handy mechanism for
doing that with `SuperConfig`:

```ruby
Config = SuperConfig.new do
  credential :api_secret_key
  credential :slack_oauth_credentials do |creds|
    SlackCredentials.new(creds)
  end
end

Config.api_secret_key
Config.slack_oauth_credentials
#=> The value stored under `Rails.application.credentials[:api_secret_key]`
```

### Types

You can coerce values to the following types:

- `string`: Is the default. E.g. `optional :name, string`.
- `int`: E.g. `optional :timeout, int`.
- `float`: E.g. `optional :wait, float`.
- `bigdecimal`: E.g. `optional :fee, bigdecimal`.
- `bool`: E.g. `optional :force_ssl, bool`. Any of `yes`, `true` or `1` is
  considered as `true`. Any other value will be coerced to `false`.
- `symbol`: E.g. `optional :app_name, symbol`.
- `array`: E.g. `optional :chars, array` or `optional :numbers, array(int)`. The
  environment variable must be something like `a,b,c`.
- `json`: E.g. `mandatory :keyring, json`. The environment variable must be
  parseable by `JSON.parse(content)`.

### Report

Sometimes it gets hard to understand what's set and what's not. In this case,
you can get a report by calling `SuperConfig::Base#report`. If you're using
Rails, you can create a rake task like this:

```ruby
# frozen_string_literal: true

desc "Show SuperConfig report"
task superconfig: [:environment] do
  puts YourAppNamespace::Config.report
end
```

Then, change your configuration so it doesn't raise an exception.

```ruby
# frozen_string_literal: true
# file: config/config.rb

module YourAppNamespace
  Config = SuperConfig.new(raise_exception: false) do
    mandatory :database_url, string
    optional :app_name, string
    optional :wait, string
    optional :force_ssl, bool, true
  end
end
```

Finally, run the following command:

```console
$ rails superconfig
❌ DATABASE_URL is not set (mandatory)
✅ APP_NAME is set (optional)
⚠️ WAIT is not set (optional)
✅ FORCE_SSL is not set, but has default value (optional)
```

### Dotenv integration

If you're using [dotenv](https://rubygems.org/gems/dotenv), you can simply
require `superconfig/dotenv`. This will load environment variables from
`.env.local.%{environment}`, `.env.local`, `.env.%{environment}` and `.env`
files, respectively. You _must_ add `dotenv` to your `Gemfile`.

```ruby
require "superconfig/dotenv"
```

### Configuring Rails

If you want to use `SuperConfig` even on your Rails configuration files like
`database.yml` and `secrets.yml`, you must load it from `config/boot.rb`, right
after setting up Bundler.

```ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

# Set up gems listed in the Gemfile.
require "bundler/setup"

# Load configuration.
require "superconfig/dotenv"
require File.expand_path("../config", __FILE__)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/fnando/superconfig. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

## Icon

Icon made by [eucalyp](https://www.flaticon.com/authors/eucalyp) from
[Flaticon](https://www.flaticon.com/) is licensed by Creative Commons BY 3.0.
