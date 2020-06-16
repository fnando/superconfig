# frozen_string_literal: true

require "env_vars"
require "dotenv"

env = ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
Dotenv.load ".env.local.#{env}", ".env.local", ".env.#{env}", ".env"
