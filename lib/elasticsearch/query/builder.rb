module Elasticsearch
  class Query
    class Builder
      class UnknownOptionsKeyException < StandardError; end
      attr_reader :data

      def initialize(use_default_context = true, &block)
        @data = {}
        @fields = []
        @use_default_context = use_default_context
        self.instance_exec(&block) if block_given?
      end

      def self.build(&block)
        new(&block).as_json
      end

      QUERY_STRING_OPTION_FIELDS = %w{
        query default_field default_operator analyzer allow_leading_wildcard lowercase_expanded_terms enable_position_increments fuzzy_max_expansions
        fuzziness fuzzy_prefix_length phrase_slop boost analyze_wildcard auto_generate_phrase_queries minimum_should_match lenient locale
      }
      def query_string(query, options = {})
        unknown_keys = options.keys.map(&:to_s) - QUERY_STRING_OPTION_FIELDS
        raise UnknownOptionsKeyException.new("Unknown query_string option keys: [#{unknown_keys.join(", ")}]") unless unknown_keys.empty?
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
          if field.condition
            d[:bool][field.condition] ||= []
            d[:bool][field.condition] << field.as_json
          else
            d.deep_merge! field.as_json
          end
        end

        if @use_default_context
          { query: Utils.as_json(d) }.tap do |result|
            result[:sort] = @sort if @sort
          end
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
        criteria = nil
        case options_or_value
        when String, Symbol
          case options_or_value.to_s.downcase
          when "asc", "desc"
            criteria = {order: options_or_value.to_s.downcase}
          else
            raise "String sort criteria must be 'asc' or 'desc'"
          end
        when Fixnum
          case options_or_value
          when 1
            criteria = {order: "asc"}
          when -1
            criteria = {order: "desc"}
          else
            raise "Integer sort criteria must be 1 or -1"
          end
        when Hash
          criteria = options_or_value
        else
          raise "Sort value must be a string or a hash of ES sort options"
        end

        @sort ||= []
        @sort << {field => criteria}
        # case options_or_value
        # when String
        #   @sort << {field => {order: options_or_value}}
        # when Hash
        #   @sort << {field => options_or_value}
        # end
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

      def method_missing(method, *args)
        if args.empty?
          field method
        else
          super
        end
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