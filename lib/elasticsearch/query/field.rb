module Elasticsearch
  class Query
    class Field
      attr_reader :ranges, :ops

      def initialize(name)
        @name  = name

        @ranges = {}
        @ops    = {}
      end

      def gt(val)
        range :gt, val
      end

      def lt(val)
        range :lt, val
      end

      def gte(val)
        range :gte, val
      end

      def lte(val)
        range :lte, val
      end

      def is(val)
        op :term, val
      end
      alias_method :equals, :is

      def match(text, options = {})
        options[:query] = text
        if v = options.delete(:phrase)
          if v == :prefix || options.delete(:prefix)
            op :match_phrase_prefix, options
          else
            op :match_phrase, options
          end
        else
          op :match, options
        end
      end

      def all_of(t)
        terms t, t.length
      end
      alias_method :all, :all_of

      def any_of(t)
        terms t, 1
      end
      alias_method :in, :any_of

      def terms(t, number)
        @ops[:terms] ||= []
        @ops[:terms] << {@name => t, :minimum_should_match => number}
      end

      def regex(regex)
        @ops[:regex] ||= []
        @ops[:regex] << {@name => regex}
      end

      def as_json
        @ops.dup do |r|
          r[:range] = @ranges unless @ranges.empty?
        end
      end

      private

      def range(op, val)
        @ranges[@name] ||= {}
        @ranges[@name][op] = val
        self
      end

      def op(op, val)
        @ops[op] ||= {}
        @ops[op][@name] = val
        self
      end
    end
  end
end