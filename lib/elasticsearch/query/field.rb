module Elasticsearch
  class Query
    class Field
      attr_reader :ranges, :ops, :condition

      def initialize(name)
        @name  = name

        @ranges = {}
        @ops    = {}
      end

      def must
        @condition = :must
        self
      end
      alias_method :must_be, :must

      def must_not
        @condition = :must_not
        self
      end
      alias_method :must_not_be, :must_not

      def should
        @condition = :should
        self
      end
      alias_method :should_be, :should

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
      alias_method :be, :is

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

      def match_all(t)
        terms t, t.length
      end
      alias_method :all_of, :match_all
      alias_method :all, :match_all

      def match_any(t)
        terms t, 1
      end
      alias_method :any_of, :match_any
      alias_method :in, :match_any

      def match_at_least(t, number)
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