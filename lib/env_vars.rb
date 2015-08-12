module Env
  class Vars
    VERSION = '0.1.0'
    BOOL_TRUE = ['yes', 'true', '1', true]
    BOOL_FALSE = ['no', 'false']

    MissingEnvironmentVariable = Class.new(StandardError)

    def initialize(&block)
      instance_eval(&block)
    end

    def set(name, type, default = nil, required: false)
      name = name.to_s
      env_var = name.upcase
      name = "#{name}?" if type == bool

      validate!(env_var, required)

      define_singleton_method(name) do
        value = ENV[env_var] || default

        case type
        when bool
          BOOL_TRUE.include?(value)
        when int
          Integer(value) if !BOOL_FALSE.include?(value) && value
        else
          value
        end
      end
    end

    def validate!(env_var, required)
      raise MissingEnvironmentVariable, "#{env_var} is not defined" if required && !ENV.key?(env_var)
    end

    def mandatory(name, type)
      set(name, type, required: true)
    end

    def optional(name, type, default = nil)
      set(name, type, default)
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
  end
end
