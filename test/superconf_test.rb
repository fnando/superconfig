# frozen_string_literal: true

require "test_helper"

class SuperConfigTest < Minitest::Test
  test "generates report" do
    vars = SuperConfig.new(
      env: {"APP_NAME" => "myapp"},
      stderr: StringIO.new,
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

  test "avoids leaking information" do
    vars = SuperConfig.new { @foo = 1 }

    assert_equal "#<SuperConfig>", vars.to_s
    assert_equal "#<SuperConfig>", vars.inspect
  end

  test "defines mandatory attribute with set value" do
    vars = SuperConfig.new(env: {"APP_NAME" => "myapp"}) do
      mandatory :app_name, string
    end

    assert_equal "myapp", vars.app_name
  end

  test "defines mandatory attribute without value raises exception" do
    assert_raises(SuperConfig::MissingEnvironmentVariable) do
      SuperConfig.new(env: {}) do
        mandatory :app_name, string
      end
    end
  end

  test "raises error with description for mandatory attribute without value" do
    error_message = "APP_NAME (the app name) if not defined."

    assert_raises(SuperConfig::MissingEnvironmentVariable, error_message) do
      SuperConfig.new(env: {}) do
        mandatory :app_name, string, description: "the app name"
      end
    end
  end

  test "logs message for mandatory attribute without value" do
    stderr = StringIO.new

    SuperConfig.new(env: {}, raise_exception: false, stderr: stderr) do
      mandatory :app_name, string
    end

    assert_equal "[SUPERCONF] APP_NAME is not defined.\n",
                 stderr.tap(&:rewind).read
  end

  test "logs colored message for mandatory attribute without value" do
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

  test "logs description for mandatory attribute without value" do
    stderr = StringIO.new

    SuperConfig.new(env: {}, raise_exception: false, stderr: stderr) do
      mandatory :app_name, string, description: "the app name"
    end

    assert_equal "[SUPERCONF] APP_NAME (the app name) is not defined.\n",
                 stderr.tap(&:rewind).read
  end

  test "defines optional attribute with set value" do
    vars = SuperConfig.new(env: {"APP_NAME" => "myapp"}) do
      optional :app_name, string
    end

    assert_equal "myapp", vars.app_name
  end

  test "defines optional without value" do
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

  test "coerces symbol" do
    vars = SuperConfig.new(env: {"APP_NAME" => "myapp"}) do
      mandatory :app_name, symbol
    end

    assert_equal :myapp, vars.app_name
  end

  test "does not coerce nil values to symbol" do
    vars = SuperConfig.new(env: {}) do
      optional :app_name, symbol
    end

    assert_nil vars.app_name
  end

  test "coerces float" do
    vars = SuperConfig.new(env: {"WAIT" => "0.01"}) do
      mandatory :wait, float
    end

    assert_in_delta 0.01, vars.wait
  end

  test "coerces bigdecimal" do
    vars = SuperConfig.new(env: {"FEE" => "0.0001"}) do
      mandatory :fee, bigdecimal
    end

    assert_equal BigDecimal("0.0001"), vars.fee
    assert_kind_of BigDecimal, vars.fee
  end

  test "does not coerce nil values to float" do
    vars = SuperConfig.new(env: {}) do
      optional :wait, float
    end

    assert_nil vars.wait
  end

  test "coerces array" do
    vars = SuperConfig.new(env: {"CHARS" => "a, b, c"}) do
      mandatory :chars, array
    end

    assert_equal %w[a b c], vars.chars
  end

  test "coerces array (without spaces)" do
    vars = SuperConfig.new(env: {"CHARS" => "a,b,c"}) do
      mandatory :chars, array
    end

    assert_equal %w[a b c], vars.chars
  end

  test "coerces array and items" do
    vars = SuperConfig.new(env: {"CHARS" => "a,b,c"}) do
      mandatory :chars, array(symbol)
    end

    assert_equal %i[a b c], vars.chars
  end

  test "does not coerce nil values to array" do
    vars = SuperConfig.new(env: {}) do
      optional :chars, array
    end

    assert_nil vars.chars
  end

  test "returns default boolean" do
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

      refute_predicate vars, :force_ssl?
    end
  end

  test "coerces int value" do
    vars = SuperConfig.new(env: {"TIMEOUT" => "10"}) do
      mandatory :timeout, int
    end

    assert_equal 10, vars.timeout
  end

  test "raises exception with invalid int" do
    vars = SuperConfig.new(env: {"TIMEOUT" => "invalid"}) do
      mandatory :timeout, int
    end

    assert_raises(ArgumentError) do
      vars.timeout
    end
  end

  test "does not coerce int when negative bool is set" do
    vars = SuperConfig.new(env: {"TIMEOUT" => "false"}) do
      mandatory :timeout, int
    end

    assert_nil vars.timeout
  end

  test "coerces json value" do
    vars = SuperConfig.new(env: {"KEYRING" => %[{"1":"SECRET"}]}) do
      mandatory :keyring, json
    end

    assert_equal("SECRET", vars.keyring["1"])
  end

  test "avoids leaking data when json is invalid" do
    vars = SuperConfig.new(env: {"KEYRING" => %[invalid]}) do
      mandatory :keyring, json
    end

    assert_raises(ArgumentError, "KEYRING is not a valid JSON string") do
      vars.keyring
    end
  end

  test "creates alias" do
    vars = SuperConfig.new(env: {"RACK_ENV" => "development"}) do
      mandatory :rack_env, string, aliases: %w[env]
    end

    assert_equal "development", vars.rack_env
    assert_equal "development", vars.env
  end

  test "gets all caps variable" do
    vars = SuperConfig.new(env: {"TZ" => "Etc/UTC"}) do
      mandatory :tz, string
    end

    assert_equal "Etc/UTC", vars.tz
  end

  test "sets arbitrary property" do
    vars = SuperConfig.new do
      property :number, -> { 1234 }
    end

    assert_equal 1234, vars.number
  end

  test "sets arbitrary property with a block" do
    vars = SuperConfig.new do
      property :number do
        1234
      end
    end

    assert_equal 1234, vars.number
  end

  test "caches generated values" do
    numbers = [1, 2]

    vars = SuperConfig.new do
      property(:number) { numbers.shift }
    end

    assert_equal 1, vars.number
    assert_equal 1, vars.number
  end

  test "does not cache generated values" do
    numbers = [1, 2]

    vars = SuperConfig.new do
      property(:number, cache: false) { numbers.shift }
    end

    assert_equal 1, vars.number
    assert_equal 2, vars.number
  end

  test "raises error when no callable has been passed to property" do
    assert_raises(Exception) do
      SuperConfig.new { property(:something) }
    end
  end

  test "uses lazy property evaluation" do
    numbers = [1, 2]

    vars = SuperConfig.new do
      property(:number) { numbers.shift }
    end

    assert_equal [1, 2], numbers

    vars.number

    assert_equal [2], numbers
  end

  test "wraps Rails credentials" do
    vars = SuperConfig.new do
      credential(:secret)
      credential(:another_secret, &:upcase)
    end

    assert_equal "secret", vars.secret
    assert_equal "ANOTHER_SECRET", vars.another_secret
  end
end
