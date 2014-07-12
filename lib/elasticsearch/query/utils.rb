module Elasticsearch
  class Query
    class Utils
      def self.as_json(object)
        case object
        when Hash
          object.each do |key, val|
            object[key] = as_json(val)
          end
        when Array
          object.map {|v| as_json v }
        else
          if object.respond_to? :as_json
            object.as_json
          else
            object
          end
        end
      end
    end
  end
end