require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "bundler/setup"
require "env_vars"
require "minitest/autorun"
require "minitest/utils"
