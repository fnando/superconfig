# frozen_string_literal: true

require "superconfig"
require "dotenv"

env = ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
Dotenv.load ".env.local.#{env}", ".env.local", ".env.#{env}", ".env"
