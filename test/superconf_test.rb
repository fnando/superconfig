# frozen_string_literal: true

require "test_helper"

class SuperConfigTest < Minitest::Test
  test "generate report" do
    vars = SuperConfig.new(
      env: {"APP_NAME" => "myapp"},
      raise_exception: false
    ) do
      mandatory :database_url, string
      optional :app_name, string
      optional :wait, int
      optional :force_ssl, bool, true
    end

    report = vars.report

    assert_includes report, "❌ DATABASE_URL is not set (mandatory)\n"
    assert_includes report, "✅ APP_NAME is set (optional)\n"
    assert_includes report, "⚠️ WAIT is not set (optional)\n"
    assert_includes report,
                    "✅ FORCE_SSL is not set, but has default value (optional)\n"
  end

  test "avoid leaking information" do
    vars = SuperConfig.new { @foo = 1 }

    assert_equal "#<SuperConfig>", vars.to_s
    assert_equal "#<SuperConfig>", vars.inspect
  end

  test "mandatory with set value" do
    vars = SuperConfig.new(env: {"APP_NAME" => "myapp"}) do
      mandatory :app_name, string
    end

    assert_equal "myapp", vars.app_name
  end

  test "mandatory without value raises exception" do
    assert_raises(SuperConfig::MissingEnvironmentVariable) do
      SuperConfig.new(env: {}) do
        mandatory :app_name, string
      end
    end
  end

  test "mandatory without value raises exception (description)" do
    error_message = "APP_NAME (the app name) if not defined."

    assert_raises(SuperConfig::MissingEnvironmentVariable, error_message) do
      SuperConfig.new(env: {}) do
        mandatory :app_name, string, description: "the app name"
      end
    end
  end

  test "mandatory without value logs message" do
    stderr = StringIO.new

    SuperConfig.new(env: {}, raise_exception: false, stderr: stderr) do
      mandatory :app_name, string
    end

    assert_equal "[SUPERCONF] APP_NAME is not defined.\n",
                 stderr.tap(&:rewind).read
  end

  test "mandatory without value logs colored message" do
    stderr = Class.new(StringIO) do
      def tty?
        true
      end
    end.new

    SuperConfig.new(env: {}, raise_exception: false, stderr: stderr) do
      mandatory :app_name, string
    end

    assert_equal "\e[31m[SUPERCONF] APP_NAME is not defined.\e[0m\n",
                 stderr.tap(&:rewind).read
  end

  test "mandatory without value logs message (description)" do
    stderr = StringIO.new

    SuperConfig.new(env: {}, raise_exception: false, stderr: stderr) do
      mandatory :app_name, string, description: "the app name"
    end

    assert_equal "[SUPERCONF] APP_NAME (the app name) is not defined.\n",
                 stderr.tap(&:rewind).read
  end

  test "optional with set value" do
    vars = SuperConfig.new(env: {"APP_NAME" => "myapp"}) do
      optional :app_name, string
    end

    assert_equal "myapp", vars.app_name
  end

  test "defines optional" do
    vars = SuperConfig.new(env: {}) do
      optional :app_name, string
    end

    assert_nil vars.app_name
  end

  test "defines optional with default value" do
    vars = SuperConfig.new(env: {}) do
      optional :app_name, string, "myapp"
    end

    assert_equal "myapp", vars.app_name
  end

  test "coerce symbol" do
    vars = SuperConfig.new(env: {"APP_NAME" => "myapp"}) do
      mandatory :app_name, symbol
    end

    assert_equal :myapp, vars.app_name
  end

  test "do not coerce nil values to symbol" do
    vars = SuperConfig.new(env: {}) do
      optional :app_name, symbol
    end

    assert_nil vars.app_name
  end

  test "coerce float" do
    vars = SuperConfig.new(env: {"WAIT" => "0.01"}) do
      mandatory :wait, float
    end

    assert_in_delta 0.01, vars.wait
  end

  test "coerce bigdecimal" do
    vars = SuperConfig.new(env: {"FEE" => "0.0001"}) do
      mandatory :fee, bigdecimal
    end

    assert_equal BigDecimal("0.0001"), vars.fee
    assert_kind_of BigDecimal, vars.fee
  end

  test "do not coerce nil values to float" do
    vars = SuperConfig.new(env: {}) do
      optional :wait, float
    end

    assert_nil vars.wait
  end

  test "coerce array" do
    vars = SuperConfig.new(env: {"CHARS" => "a, b, c"}) do
      mandatory :chars, array
    end

    assert_equal %w[a b c], vars.chars
  end

  test "coerce array (without spaces)" do
    vars = SuperConfig.new(env: {"CHARS" => "a,b,c"}) do
      mandatory :chars, array
    end

    assert_equal %w[a b c], vars.chars
  end

  test "coerce array and items" do
    vars = SuperConfig.new(env: {"CHARS" => "a,b,c"}) do
      mandatory :chars, array(symbol)
    end

    assert_equal %i[a b c], vars.chars
  end

  test "do not coerce nil values to array" do
    vars = SuperConfig.new(env: {}) do
      optional :chars, array
    end

    assert_nil vars.chars
  end

  test "return default boolean" do
    vars = SuperConfig.new(env: {}) do
      optional :force_ssl, bool, true
    end

    assert vars.force_ssl?
  end

  test "coerces bool value" do
    %w[yes true 1].each do |value|
      vars = SuperConfig.new(env: {"FORCE_SSL" => value}) do
        mandatory :force_ssl, bool
      end

      assert vars.force_ssl?
    end

    %w[no false 0].each do |value|
      vars = SuperConfig.new(env: {"FORCE_SSL" => value}) do
        mandatory :force_ssl, bool
      end

      refute vars.force_ssl?
    end
  end

  test "coerces int value" do
    vars = SuperConfig.new(env: {"TIMEOUT" => "10"}) do
      mandatory :timeout, int
    end

    assert_equal 10, vars.timeout
  end

  test "raises exception with invalid int" do
    assert_raises(ArgumentError) do
      vars = SuperConfig.new(env: {"TIMEOUT" => "invalid"}) do
        mandatory :timeout, int
      end

      vars.timeout
    end
  end

  test "do not coerce int when negative bool is set" do
    vars = SuperConfig.new(env: {"TIMEOUT" => "false"}) do
      mandatory :timeout, int
    end

    assert_nil vars.timeout
  end

  test "coerces json value" do
    vars = SuperConfig.new(env: {"KEYRING" => %[{"1":"SECRET"}]}) do
      mandatory :keyring, json
    end

    assert_equal vars.keyring["1"], "SECRET"
  end

  test "create alias" do
    vars = SuperConfig.new(env: {"RACK_ENV" => "development"}) do
      mandatory :rack_env, string, aliases: %w[env]
    end

    assert_equal "development", vars.rack_env
    assert_equal "development", vars.env
  end

  test "get all caps variable" do
    vars = SuperConfig.new(env: {"TZ" => "Etc/UTC"}) do
      mandatory :tz, string
    end

    assert_equal "Etc/UTC", vars.tz
  end

  test "set arbitrary property" do
    vars = SuperConfig.new do
      property :number, -> { 1234 }
    end

    assert_equal 1234, vars.number
  end

  test "set arbitrary property with a block" do
    vars = SuperConfig.new do
      property :number do
        1234
      end
    end

    assert_equal 1234, vars.number
  end

  test "cache generated values" do
    numbers = [1, 2]

    vars = SuperConfig.new do
      property(:number) { numbers.shift }
    end

    assert_equal 1, vars.number
    assert_equal 1, vars.number
  end

  test "don't cache generated values" do
    numbers = [1, 2]

    vars = SuperConfig.new do
      property(:number, cache: false) { numbers.shift }
    end

    assert_equal 1, vars.number
    assert_equal 2, vars.number
  end

  test "raise when no callable has been passed to property" do
    assert_raises(Exception) do
      SuperConfig.new { property(:something) }
    end
  end

  test "lazy evaluate properties" do
    numbers = [1, 2]

    vars = SuperConfig.new do
      property(:number) { numbers.shift }
    end

    assert_equal [1, 2], numbers
    vars.number
    assert_equal [2], numbers
  end

  test "wrap Rails credentials" do
    vars = SuperConfig.new do
      credential(:secret)
      credential(:another_secret, &:upcase)
    end

    assert_equal "secret", vars.secret
    assert_equal "ANOTHER_SECRET", vars.another_secret
  end
end
