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
            args = IntegerFu::MappableInteger.symbolize(args)
            self[attr_name] = IntegerFu::MappableInteger.array_to_integer(args, options[:values])
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, IntegerFu::ActiveRecordExtensions)