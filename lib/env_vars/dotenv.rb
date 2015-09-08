require 'env_vars'
require 'dotenv'

env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
Dotenv.load '.env.local', ".env.#{env}", '.env'
