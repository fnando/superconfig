# frozen_string_literal: true

module SuperConfig
  VERSION = "2.2.1"

  MissingEnvironmentVariable = Class.new(StandardError)
  MissingCallable = Class.new(StandardError)

  def self.new(...)
    Base.new(...)
  end

  class Base
    BOOL_TRUE = ["yes", "true", "1", true].freeze
    BOOL_FALSE = %w[no false].freeze

    def initialize(
      env: ENV,
      prefix: nil,
      raise_exception: true,
      stderr: $stderr,
      &block
    )
      @env = env
      @prefix = prefix
      @raise_exception = raise_exception
      @stderr = stderr
      @attributes = {}
      @__cache__ = {}
      instance_eval(&block)
    end

    def to_s
      "#<SuperConfig>"
    end
    alias inspect to_s

    def validate!(env_var, required, description)
      env_var = [@prefix, env_var].compact.join("_").upcase

      return unless required
      return if @env.key?(env_var)

      message = env_var.to_s
      message << " (#{description})" if description
      message << " is not defined."

      raise MissingEnvironmentVariable, message if @raise_exception

      message = "[SUPERCONF] #{message}"
      message = "\e[31m#{message}\e[0m" if @stderr.tty?
      @stderr << message << "\n"
    end

    def mandatory(name, type, aliases: [], description: nil)
      assign(
        name,
        type,
        required: true,
        aliases:,
        description:
      )
    end

    def optional(name, type, default = nil, aliases: [], description: nil)
      assign(name, type, default, aliases:, description:)
    end

    def set(name, value)
      silence_warnings do
        property(name) { value }
      end
    end

    def property(name, func = nil, cache: true, description: nil, &block) # rubocop:disable Lint/UnusedMethodArgument
      callable = func || block

      unless callable
        raise MissingCallable, "arg[1] must respond to #call or pass a block"
      end

      if cache
        define_singleton_method(name) do
          @__cache__[name.to_sym] ||= callable.call
        end
      else
        define_singleton_method(name) { callable.call }
      end
    end

    def credential(name, &block)
      define_singleton_method(name) do
        @__cache__[:"_credential_#{name}"] ||= begin
          value = Rails.application.credentials.fetch(name)
          block ? block.call(value) : value # rubocop:disable Performance/RedundantBlockCall
        end
      end
    end

    def int
      :int
    end

    def string
      :string
    end

    def bool
      :bool
    end

    def symbol
      :symbol
    end

    def float
      :float
    end

    def bigdecimal
      require "bigdecimal"
      :bigdecimal
    end

    def array(type = string)
      [:array, type]
    end

    def json
      :json
    end

    def report
      attrs = @attributes.sort

      report = attrs.each_with_object([]) do |(env_var, info), buffer|
        icon, message = if @env.key?(env_var)
                          ["✅", "is set"]
                        elsif info[:required]
                          ["❌", "is not set"]
                        elsif !info[:required] && !info[:default].nil?
                          ["✅", "is not set, but has default value"]
                        else
                          ["⚠️", "is not set"]
                        end

        label = if info[:required]
                  "mandatory"
                else
                  "optional"
                end

        buffer << [icon, env_var, message, "(#{label})"].join(" ")
      end

      "#{report.join("\n")}\n"
    end

    private def coerce_to_string(_name, value)
      value
    end

    private def coerce_to_bool(_name, value)
      BOOL_TRUE.include?(value)
    end

    private def coerce_to_int(_name, value)
      Integer(value) if !BOOL_FALSE.include?(value) && value
    end

    private def coerce_to_float(_name, value)
      Float(value) if value
    end

    private def coerce_to_bigdecimal(_name, value)
      BigDecimal(value) if value
    end

    private def coerce_to_symbol(_name, value)
      value&.to_sym
    end

    private def coerce_to_array(name, value, type)
      value&.split(/, */)&.map {|v| coerce(name, type, v) }
    end

    private def coerce_to_json(name, value)
      value && JSON.parse(value)
    rescue JSON::ParserError
      raise ArgumentError, "#{name} is not a valid JSON string"
    end

    private def coerce(name, type, value)
      main_type, sub_type = type
      args = [name, value]
      args << sub_type if sub_type

      send(:"coerce_to_#{main_type}", *args)
    end

    private def assign(
      name,
      type,
      default = nil,
      required: false,
      aliases: [],
      description: nil
    )
      name = name.to_s
      env_var = [@prefix, name].compact.join("_").upcase

      @attributes[env_var] = {required:, default:}

      name = "#{name}?" if type == bool

      validate!(env_var, required, description)

      define_singleton_method(name) do
        return default unless @env.key?(env_var)

        coerce(env_var, type, @env[env_var])
      end

      aliases.each do |alias_name|
        define_singleton_method(alias_name, method(name))
      end
    end

    private def silence_warnings(&)
      old_verbose = $VERBOSE
      $VERBOSE = nil
      yield
    ensure
      $VERBOSE = old_verbose
    end
  end
end
