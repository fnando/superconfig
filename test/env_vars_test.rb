require "test_helper"

class EnvVarsTest < Minitest::Test
  setup do
    ENV.delete("APP_NAME")
    ENV.delete("FORCE_SSL")
    ENV.delete("TIMEOUT")
    ENV.delete("RACK_ENV")
    ENV.delete("TZ")
  end

  test "mandatory with set value" do
    ENV["APP_NAME"] = "myapp"

    vars = Env::Vars.new do
      mandatory :app_name, "myapp"
    end

    assert_equal "myapp", vars.app_name
  end

  test "mandatory without value raises exception" do
    assert_raises(Env::Vars::MissingEnvironmentVariable) do
      Env::Vars.new do
        mandatory :app_name, "myapp"
      end
    end
  end

  test "optional with set value" do
    ENV["APP_NAME"] = "myapp"

    vars = Env::Vars.new do
      optional :app_name, string
    end

    assert_equal "myapp", vars.app_name
  end

  test "defines optional" do
    vars = Env::Vars.new do
      optional :app_name, string
    end

    assert vars.app_name.nil?
  end

  test "defines optional with default value" do
    vars = Env::Vars.new do
      optional :app_name, string, "myapp"
    end

    assert_equal "myapp", vars.app_name
  end

  test "return default boolean" do
    vars = Env::Vars.new do
      optional :force_ssl, bool, true
    end

    assert vars.force_ssl?
  end

  test 'coerces bool value' do
    ["yes", "true", "1"].each do |value|
      ENV["FORCE_SSL"] = value
      vars = Env::Vars.new do
        mandatory :force_ssl, bool
      end

      assert vars.force_ssl?
    end

    ["no", "false", "0"].each do |value|
      ENV["FORCE_SSL"] = value
      vars = Env::Vars.new do
        mandatory :force_ssl, bool
      end

      refute vars.force_ssl?
    end
  end

  test "coerces int value" do
    ENV["TIMEOUT"] = "10"
    vars = Env::Vars.new do
      mandatory :timeout, int
    end

    assert_equal 10, vars.timeout
  end

  test "raises exception with invalid int" do
    assert_raises(ArgumentError) do
      ENV["TIMEOUT"] = "invalid"
      vars = Env::Vars.new do
        mandatory :timeout, int
      end

      vars.timeout
    end
  end

  test "do not coerce int when negative bool is set" do
    ENV["TIMEOUT"] = "false"

    vars = Env::Vars.new do
      mandatory :timeout, int
    end

    assert vars.timeout.nil?
  end

  test "create alias" do
    ENV["RACK_ENV"] = "development"
    vars = Env::Vars.new do
      mandatory :rack_env, string, aliases: %w[env]
    end

    assert_equal "development", vars.rack_env
    assert_equal "development", vars.env
  end

  test "get all caps variable" do
    ENV["TZ"] = "Etc/UTC"
    vars = Env::Vars.new do
      mandatory :tz, string
    end

    assert_equal "Etc/UTC", vars.tz
  end

  test "set arbitrary property" do
    vars = Env::Vars.new do
      property :number, -> { 1234 }
    end

    assert_equal 1234, vars.number
  end
end
