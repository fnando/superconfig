# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "rails"
require "superconfig"
require "minitest/autorun"
require "minitest/utils"

ENV["RAILS_MASTER_KEY"] = "ruby-on-rails-sample-credentials"

class TestApp < Rails::Application
  def credentials
    @credentials ||= encrypted("#{__dir__}/test.yml.enc")
  end
end

ActiveSupport::EncryptedFile.new(
  content_path: Pathname.new("#{__dir__}/test.yml.enc"),
  key_path: Pathname.new("#{__dir__}/test.key"),
  env_key: "RAILS_MASTER_KEY",
  raise_if_missing_key: true
).write(YAML.dump(secret: "secret", another_secret: "another_secret"))
