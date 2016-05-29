module Env
  class Vars
    VERSION = "0.4.0"
    BOOL_TRUE = ["yes", "true", "1", true]
    BOOL_FALSE = ["no", "false"]

    MissingEnvironmentVariable = Class.new(StandardError)

    def initialize(env = ENV, &block)
      @env = env
      instance_eval(&block)
    end

    def set(name, type, default = nil, required: false, aliases: [])
      name = name.to_s
      env_var = name.upcase
      name = "#{name}?" if type == bool

      validate!(env_var, required)

      define_singleton_method(name) do
        return default unless @env.key?(env_var)

        value = @env[env_var]
        coercion_method = "coerce_to_#{type}"

        send(coercion_method, value)
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

    def property(name, func)
      value = func.call
      define_singleton_method(name) { value }
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

    def coerce_to_symbol(value)
      value && value.to_sym
    end
  end
end
