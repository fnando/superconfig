# frozen_string_literal: true

module SuperConfig
  VERSION = "2.1.0"

  MissingEnvironmentVariable = Class.new(StandardError)
  MissingCallable = Class.new(StandardError)

  def self.new(**kwargs, &block)
    Base.new(**kwargs, &block)
  end

  class Base
    BOOL_TRUE = ["yes", "true", "1", true].freeze
    BOOL_FALSE = %w[no false].freeze

    def initialize(env: ENV, raise_exception: true, stderr: $stderr, &block)
      @env = env
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

    def set(
      name,
      type,
      default = nil,
      required: false,
      aliases: [],
      description: nil
    )
      name = name.to_s
      env_var = name.upcase

      @attributes[env_var] = {required: required, default: default}

      name = "#{name}?" if type == bool

      validate!(env_var, required, description)

      define_singleton_method(name) do
        return default unless @env.key?(env_var)

        coerce(type, @env[env_var])
      end

      aliases.each do |alias_name|
        define_singleton_method(alias_name, method(name))
      end
    end

    def validate!(env_var, required, description)
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
      set(
        name,
        type,
        required: true,
        aliases: aliases,
        description: description
      )
    end

    def optional(name, type, default = nil, aliases: [], description: nil)
      set(name, type, default, aliases: aliases, description: description)
    end

    def property(name, func = nil, cache: true, description: nil, &block) # rubocop:disable Lint/UnusedMethodArgument
      callable = (func || block)

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
        @__cache__["_credential_#{name}".to_sym] ||= begin
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

    private def coerce_to_string(value)
      value
    end

    private def coerce_to_bool(value)
      BOOL_TRUE.include?(value)
    end

    private def coerce_to_int(value)
      Integer(value) if !BOOL_FALSE.include?(value) && value
    end

    private def coerce_to_float(value)
      Float(value) if value
    end

    private def coerce_to_bigdecimal(value)
      BigDecimal(value) if value
    end

    private def coerce_to_symbol(value)
      value&.to_sym
    end

    private def coerce_to_array(value, type)
      value&.split(/, */)&.map {|v| coerce(type, v) }
    end

    private def coerce_to_json(value)
      value && JSON.parse(value)
    end

    private def coerce(type, value)
      main_type, sub_type = type
      args = [value]
      args << sub_type if sub_type

      send("coerce_to_#{main_type}", *args)
    end
  end
end
