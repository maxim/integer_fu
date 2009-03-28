require 'helpers'
require 'mappable_integer'

module IntegerFu
  class IntegerFuError < Exception; end
  
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
        
        named_scope attr_name, proc { |*args| 
          args = helpers.symbolize(args.flatten)
          cumulative_value = helpers.array_to_integer_with_keys(options[:values], args)
          matching_integers = (0..(2**options[:values].size-1)).select{|n| n & cumulative_value == cumulative_value }
          {:conditions => {"#{self.table_name}.#{attr_name}" => matching_integers}}
        }
      end
    end
  end
end

ActiveRecord::Base.send(:include, IntegerFu::ActiveRecordExtensions)