require "test_helper"

class EnvVarsTest < Minitest::Test
  test "mandatory with set value" do
    vars = Env::Vars.new("APP_NAME" => "myapp") do
      mandatory :app_name, string
    end

    assert_equal "myapp", vars.app_name
  end

  test "mandatory without value raises exception" do
    assert_raises(Env::Vars::MissingEnvironmentVariable) do
      Env::Vars.new({}) do
        mandatory :app_name, string
      end
    end
  end

  test "optional with set value" do
    vars = Env::Vars.new("APP_NAME" => "myapp") do
      optional :app_name, string
    end

    assert_equal "myapp", vars.app_name
  end

  test "defines optional" do
    vars = Env::Vars.new({}) do
      optional :app_name, string
    end

    assert_nil vars.app_name
  end

  test "defines optional with default value" do
    vars = Env::Vars.new({}) do
      optional :app_name, string, "myapp"
    end

    assert_equal "myapp", vars.app_name
  end

  test "return default boolean" do
    vars = Env::Vars.new({}) do
      optional :force_ssl, bool, true
    end

    assert vars.force_ssl?
  end

  test "coerces bool value" do
    %w[yes true 1].each do |value|
      vars = Env::Vars.new("FORCE_SSL" => value) do
        mandatory :force_ssl, bool
      end

      assert vars.force_ssl?
    end

    %w[no false 0].each do |value|
      vars = Env::Vars.new("FORCE_SSL" => value) do
        mandatory :force_ssl, bool
      end

      refute vars.force_ssl?
    end
  end

  test "coerces int value" do
    vars = Env::Vars.new("TIMEOUT" => "10") do
      mandatory :timeout, int
    end

    assert_equal 10, vars.timeout
  end

  test "raises exception with invalid int" do
    assert_raises(ArgumentError) do
      vars = Env::Vars.new("TIMEOUT" => "invalid") do
        mandatory :timeout, int
      end

      vars.timeout
    end
  end

  test "do not coerce int when negative bool is set" do
    vars = Env::Vars.new("TIMEOUT" => "false") do
      mandatory :timeout, int
    end

    assert_nil vars.timeout
  end

  test "create alias" do
    vars = Env::Vars.new("RACK_ENV" => "development") do
      mandatory :rack_env, string, aliases: %w[env]
    end

    assert_equal "development", vars.rack_env
    assert_equal "development", vars.env
  end

  test "get all caps variable" do
    vars = Env::Vars.new("TZ" => "Etc/UTC") do
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
