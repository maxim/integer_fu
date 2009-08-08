require 'helpers'
require 'mappable_integer'

module IntegerFu
  class IntegerFuError < RuntimeError; end
  
  module ActiveRecordExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
      def map_integer(attr_name, options)
        options.symbolize_keys!
        attr_name = attr_name.to_sym
        helpers = IntegerFu::Helpers
        
        if options[:values].empty?
          raise IntegerFu::IntegerFuError, "Values are required for integer mapping (attempting to map attribute \"#{attr_name}\")."
        end
        
        define_method attr_name do
          IntegerFu::MappableInteger.new(attr_name, self, options[:values])
        end
        
        define_method "#{attr_name}=" do |*args|
          args.flatten!
          
          if args.first.is_a?(Numeric) || args.first == nil
            self[attr_name] = args.first
          else
            # If dealing with hash, only need keys where values are truthy
            args = helpers.keys_with_truthy_values(args.first) if args.first.is_a?(Hash)
            args = helpers.symbolize(args)
            self[attr_name] = helpers.array_to_integer_with_keys(options[:values], args)
          end
        end
        
        for value_name in options[:values]
          class_eval <<-ruby
            def #{attr_name}_#{value_name}=(arg)
              arg = (arg == "0" ? false : arg)
              self.#{attr_name}["#{value_name}"] = arg
            end
            
            def #{attr_name}_#{value_name}
              self.#{attr_name}["#{value_name}"]
            end
          ruby
        end
        
        if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) &&
           self.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          ##
          # Optimized named scope for postgres
          #
          named_scope attr_name do |*args|
            args = helpers.symbolize(args.flatten)
            cumulative_value = helpers.array_to_integer_with_keys(options[:values], args)
            {:conditions => "(#{cumulative_value} != 0) AND (#{self.table_name}.#{attr_name} & #{cumulative_value}) = #{cumulative_value}"}
          end
        else
          named_scope attr_name, do |*args| 
            args = helpers.symbolize(args.flatten)
            cumulative_value = helpers.array_to_integer_with_keys(options[:values], args)
            matching_integers = (0..(2**options[:values].size-1)).select{|n| n & cumulative_value == cumulative_value }
            {:conditions => {"#{self.table_name}.#{attr_name}" => matching_integers}}
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, IntegerFu::ActiveRecordExtensions)