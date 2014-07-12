module Elasticsearch
  class Query
    class Builder
      attr_reader :data

      def initialize(use_default_context = true, &block)
        @data = {}
        @fields = []
        @use_default_context = use_default_context
        self.instance_exec(&block) if block_given?
      end

      def query_string(query, options = {})
        with_default_context { @data[:query_string] = options.merge(query: query) }
        self
      end

      def multi_match(query, fields, options = {})
        with_default_context { @data[:multi_match] = options.merge( query: query, fields: fields ) }
      end

      def must(&block)
        bool(:must, &block)
      end

      def must_not(&block)
        bool(:must_not, &block)
      end

      def should(&block)
        bool(:should, &block)
      end

      def as_json
        d = @data.deep_dup

        @fields.each do |field|
          d.deep_merge! field.as_json
        end
        if @use_default_context
          { query: Utils.as_json(d) }
        else
          Utils.as_json d
        end
      end

      def filter(&block)
        q = Filter.new
        q.instance_exec &block
        add :filtered, Utils.as_json(q)
      end

      def sort(field, options_or_value)
        @sort ||= []
        case options_or_value
        when String
          @sort << {field => {order: options_or_value}}
        when Hash
          @sort << {field => options_or_value}
        end
        self
      end

      def field(f)
        # Exposure to the closure
        fields = @fields
        with_default_context do
          return Field.new(f).tap {|field| fields << field }
        end
      end

      def aggregate(&block)
        @data[:aggs] ||= Aggregate.new(&block)
      end

      private

      def with_default_context(&block)
        if @use_default_context
          must(&block)
        else
          yield
        end
      end

      def bool(mode, &block)
        subquery = Builder.new(false)
        @data[:bool] ||= {}
        @data[:bool][mode] ||= []
        subquery.instance_exec(&block)
        @data[:bool][mode].push Utils.as_json(subquery)
        self
      end

      def add(field, hash)
        @data[field] ||= []
        @data[field] << hash
        self
      end
    end
  end
end