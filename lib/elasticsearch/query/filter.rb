module Elasticsearch
  class Query
    class Filter < Builder
      def filter
        raise "Can't filter from a filter"
      end

      def query(&block)
        q = Builder.new
        q.instance_exec(&block)
        @query = Utils.as_json(q)
        self
      end

      def as_json
        (@query || {}).tap do |h|
          h[:filter] = Utils.as_json(@data) unless @data.empty?
        end
      end
    end
  end
end