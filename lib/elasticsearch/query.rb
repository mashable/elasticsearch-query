require_relative "./query/builder"
require_relative "./query/filter"
require_relative "./query/aggregate"
require_relative "./query/field"
require_relative "./query/utils"

require 'active_support/all'

module Elasticsearch
  class Query
  	def self.build(&block)
  		Builder.build &block
  	end
  end
end
