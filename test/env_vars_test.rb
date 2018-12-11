require "test_helper"

class EnvVarsTest < Minitest::Test
  test "avoid leaking information" do
    vars = Env::Vars.new { @foo = 1 }

    assert_equal "#<Env::Vars>", vars.to_s
    assert_equal "#<Env::Vars>", vars.inspect
  end

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

  test "mandatory without value raises exception (description)" do
    assert_raises(Env::Vars::MissingEnvironmentVariable, "APP_NAME (the app name) if not defined") do
      Env::Vars.new({}) do
        mandatory :app_name, string, description: "the app name"
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

  test "coerce symbol" do
    vars = Env::Vars.new("APP_NAME" => "myapp") do
      mandatory :app_name, symbol
    end

    assert_equal :myapp, vars.app_name
  end

  test "do not coerce nil values to symbol" do
    vars = Env::Vars.new({}) do
      optional :app_name, symbol
    end

    assert_nil vars.app_name
  end

  test "coerce float" do
    vars = Env::Vars.new("WAIT" => "0.01") do
      mandatory :wait, float
    end

    assert_in_delta 0.01, vars.wait
  end

  test "coerce bigdecimal" do
    vars = Env::Vars.new("FEE" => "0.0001") do
      mandatory :fee, bigdecimal
    end

    assert_equal BigDecimal("0.0001"), vars.fee
    assert_kind_of BigDecimal, vars.fee
  end

  test "do not coerce nil values to float" do
    vars = Env::Vars.new({}) do
      optional :wait, float
    end

    assert_nil vars.wait
  end

  test "coerce array" do
    vars = Env::Vars.new("CHARS" => "a, b, c") do
      mandatory :chars, array
    end

    assert_equal %w[a b c], vars.chars
  end

  test "coerce array (without spaces)" do
    vars = Env::Vars.new("CHARS" => "a,b,c") do
      mandatory :chars, array
    end

    assert_equal %w[a b c], vars.chars
  end

  test "coerce array and items" do
    vars = Env::Vars.new("CHARS" => "a,b,c") do
      mandatory :chars, array(symbol)
    end

    assert_equal %i[a b c], vars.chars
  end

  test "do not coerce nil values to array" do
    vars = Env::Vars.new({}) do
      optional :chars, array
    end

    assert_nil vars.chars
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

  test "set arbitrary property with a block" do
    vars = Env::Vars.new do
      property :number do
        1234
      end
    end

    assert_equal 1234, vars.number
  end

  test "cache generated values" do
    numbers = [1, 2]

    vars = Env::Vars.new do
      property(:number) { numbers.shift }
    end

    assert_equal 1, vars.number
    assert_equal 1, vars.number
  end

  test "don't cache generated values" do
    numbers = [1, 2]

    vars = Env::Vars.new do
      property(:number, cache: false) { numbers.shift }
    end

    assert_equal 1, vars.number
    assert_equal 2, vars.number
  end

  test "raise when no callable has been passed to property" do
    assert_raises(Exception) do
      Env::Vars.new { property(:something) }
    end
  end

  test "lazy evaluate properties" do
    numbers = [1, 2]

    vars = Env::Vars.new do
      property(:number) { numbers.shift }
    end

    assert_equal [1, 2], numbers
    vars.number
    assert_equal [2], numbers
  end
end
