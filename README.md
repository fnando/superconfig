# Env::Vars

[![build status](https://travis-ci.org/fnando/env_vars.svg)](https://travis-ci.org/fnando/env_vars)

Access environment variables. Also includes presence validation, type coercion and default values.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'env_vars'
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
end

Config.database_url
Config.timeout
Config.force_ssl?
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fnando/env_vars. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

