module Elasticsearch
  class Query
    class Index
      def initialize(client, name)
        @client = client
        @name   = name
      end

      def query(options, &block)
        @client.search options.merge(index: @name), Query.build(&block)
      end
    end
  end
end