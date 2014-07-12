  class Aggregate
    def initialize(&block)
      @aggregations = []
      self.instance_exec &block
    end

    def method_missing(method, *args)
      @aggregations << AggregateField.new(method, *args)
    end

    def as_json
      @aggregations.each.with_object({}) {|agg, o| o.merge!(agg.as_json) }
    end
  end

  class AggregateField
    def initialize(function, field)
      @field = field
      @function = function
      @agg_alias = "#{field}_#{function}"
    end

    def as_json
      {@agg_alias => {@function => {field: @field}}}
    end

    def as(agg_alias)
      @agg_alias = agg_alias
    end
  end