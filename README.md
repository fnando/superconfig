![env_vars: Access environment variables. Also includes presence validation, type coercion and default values.](https://raw.githubusercontent.com/fnando/env_vars/master/env_vars.png)

<p align="center">
  <a href="https://travis-ci.org/fnando/env_vars"><img src="https://travis-ci.org/fnando/env_vars.svg" alt="Travis-CI"></a>
  <a href="https://codeclimate.com/github/fnando/env_vars"><img src="https://codeclimate.com/github/fnando/env_vars/badges/gpa.svg" alt="Code Climate"></a>
  <a href="https://codeclimate.com/github/fnando/env_vars/coverage"><img src="https://codeclimate.com/github/fnando/env_vars/badges/coverage.svg" alt="Test Coverage"></a>
  <a href="https://rubygems.org/gems/env_vars"><img src="https://img.shields.io/gem/v/env_vars.svg" alt="Gem"></a>
  <a href="https://rubygems.org/gems/env_vars"><img src="https://img.shields.io/gem/dt/env_vars.svg" alt="Gem"></a>
</p>

## Installation

Add this line to your application's Gemfile:

```ruby
gem "env_vars"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install env_vars

## Usage

```ruby
Config = Env::Vars.new do
  mandatory :database_url, string
  optional  :timeout, int, 10
  optional  :force_ssl, bool, false
  optional  :rails_env, "development", string, aliases: %w[env]
end

Config.database_url
Config.timeout
Config.force_ssl?
```

You can specify the description for both `mandatory` and `optional` methods; this will be used in exceptions.

```ruby
Config = Env::Vars.new do
  mandatory :missing_var, string, description: "this is important"
end

#=> Env::Vars::MissingEnvironmentVariable: MISSING_VAR (this is important) is not defined
```

If you're going to use `env_vars` as your main configuration object, you can also set arbitrary properties, like the following:

```ruby
Config = Env::Vars.new do
  optional :redis_url, string, "redis://127.0.0.1"
  property :redis, -> { Redis.new } # pass an object that responds to #call
  property(:now) { Time.now }       # or pass a block.
end

Config.redis.set("key", "value")
Config.redis.get("key")
#=> "value"
```

Values are cached by default. If you want to dynamically generate new values, set `cache: false`.

```ruby
Config = Env::Vars.new do
  property(:uuid, cache: false) { SecureRandom.uuid }
end
```

### Types

You can coerce values to the following types:

- `string`: Is the default. E.g. `optional :name, string`.
- `int`: E.g. `optional :timeout, int`.
- `float`: E.g. `optional :wait, float`.
- `bigdecimal`: E.g. `optional :fee, bigdecimal`.
- `bool`: E.g. `optional :force_ssl, bool`. Any of `yes`, `true` or `1` is considered as `true`. Any other value will be coerced to `false`.
- `symbol`: E.g. `optional :app_name, symbol`.
- `array`: E.g. `optional :chars, array` or `optional :numbers, array(int)`. The environment variable must be something like `a,b,c`.

### Dotenv integration

If you're using [dotenv](https://rubygems.org/gems/dotenv), you can simply require `env_vars/dotenv`. This will load environment variables from `.env.local.%{environment}`, `.env.local`, `.env.%{environment}` and `.env` files, respectively. You _must_ add `dotenv` to your `Gemfile`.

```ruby
require "env_vars/dotenv"
```

### Configuring Rails

If you want to use `env_vars` even on your Rails configuration files like `database.yml` and `secrets.yml`, you must load it from `config/boot.rb`, right after setting up Bundler.

```ruby
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

# Set up gems listed in the Gemfile.
require "bundler/setup"

# Load configuration.
require "env_vars/dotenv"
require File.expand_path("../config", __FILE__)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fnando/env_vars. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Icon

Icon made by [eucalyp](https://www.flaticon.com/authors/eucalyp) from [Flaticon](https://www.flaticon.com/) is licensed by Creative Commons BY 3.0.
