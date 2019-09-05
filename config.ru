require 'bundler'
Bundler.require

set :foo, "bar"
set :max_market_rec, 10

require './models/models'
require './app'

run SQApp