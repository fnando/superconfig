# frozen_string_literal: true

require "bigdecimal"

module Env
  class Vars
    VERSION = "0.6.0"
    BOOL_TRUE = ["yes", "true", "1", true]
    BOOL_FALSE = ["no", "false"]

    MissingEnvironmentVariable = Class.new(StandardError)
    MissingCallable = Class.new(StandardError)

    def initialize(env = ENV, &block)
      @env = env
      @__cache__ = {}
      instance_eval(&block)
    end

    def set(name, type, default = nil, required: false, aliases: [])
      name = name.to_s
      env_var = name.upcase
      name = "#{name}?" if type == bool

      validate!(env_var, required)

      define_singleton_method(name) do
        return default unless @env.key?(env_var)
        coerce(type, @env[env_var])
      end

      aliases.each do |alias_name|
        define_singleton_method(alias_name, method(name))
      end
    end

    def validate!(env_var, required)
      return unless required
      raise MissingEnvironmentVariable, "#{env_var} is not defined" unless @env.key?(env_var)
    end

    def mandatory(name, type, aliases: [])
      set(name, type, required: true, aliases: aliases)
    end

    def optional(name, type, default = nil, aliases: [])
      set(name, type, default, aliases: aliases)
    end

    def property(name, func = nil, cache: true, &block)
      callable = (func || block)
      raise MissingCallable, "arg[1] must respond to #call or pass a block" unless callable

      if cache
        define_singleton_method(name) do
          @__cache__[name.to_sym] ||= callable.call
        end
      else
        define_singleton_method(name) { callable.call }
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
      :bigdecimal
    end

    def array(type = string)
      [:array, type]
    end

    private

    def coerce_to_string(value)
      value
    end

    def coerce_to_bool(value)
      BOOL_TRUE.include?(value)
    end

    def coerce_to_int(value)
      Integer(value) if !BOOL_FALSE.include?(value) && value
    end

    def coerce_to_float(value)
      Float(value) if value
    end

    def coerce_to_bigdecimal(value)
      BigDecimal(value) if value
    end

    def coerce_to_symbol(value)
      value && value.to_sym
    end

    def coerce_to_array(value, type)
      value && value.split(/, */).map {|v| coerce(type, v) }
    end

    def coerce(type, value)
      main_type, sub_type = type
      args = [value]
      args << sub_type if sub_type

      send("coerce_to_#{main_type}", *args)
    end
  end
end
