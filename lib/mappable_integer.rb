module IntegerFu
  class MappableInteger
    include Enumerable
    include IntegerFu::Helpers
    
    def initialize(attr_name, parent_model, keys)
      @attr_name = attr_name.to_sym
      @model = parent_model
      @keys = symbolize(keys)
    end
    
    ##
    # Allows accessing values in following ways
    #   foo[1]            # behaves like an integer
    #   foo[:bar]         # returns true if :bar is marked as true
    #   foo[:bar, "baz"]  # returns true if :bar and :baz are marked true
    #
    def [](*args)
      if args.first.is_a?(Numeric)
        get_model_attr[args.first]
      else
        args.all? { |key| key_true?(key) }
      end
    end
    
    ##
    # Allows setting particular key to a boolean value (equivalent to adding/subtracting with these keys)
    #   foo[:bar] = false       # :bar is now false
    #   foo["baz"] = "string"   # :baz is set to true
    #
    def []=(arg, value)
      arg   = arg.to_sym
      value = !!value
      
      if @keys.include?(arg)
        if value
          add_keys!([arg])
        else
          remove_keys!([arg])
        end
      else
        IntegerFu.raise_undefined_key_error(arg)
      end
    end
    
    ##
    # Delegates to + operator
    #
    def <<(*args)
      self + args
    end
  
  
    ##
    # Adds multiple key identifiers (equivalent of setting them to true)
    #   foo += [:bar, "baz"]  # sets :bar and :baz to true unless they're already true
    #
    def +(*args)
      if args.first.is_a?(Numeric)
        get_model_attr + args.first
      else
        add_keys!(args)
      end
    end
    
    ##
    # Subtracts multiple key identifiers (equivalent of setting them to false)
    #   foo -= :baz   # sets :baz to false unless they're already false
    #
    def -(*args)
      if args.first.is_a?(Numeric)
        get_model_attr - args.first
      else
        remove_keys!(args)
      end
    end
    
    ##
    # Collects all keys which are set to true, returns them as an array
    #   foo.to_a    # => [:bar, :baz] (assuming :bar and :baz are set to true)
    #
    def to_a
      @keys.select{ |k| key_true?(k) }
    end
    
    ##
    # Iterates over result of #to_a
    #
    def each
      self.to_a.each do |el|
        yield(el)
      end
    end
    
    ##
    # Returns all defined keys, no matter true or false
    #
    def all
      @keys
    end
    
    ##
    # Handles magic question-mark and setter methods.
    # Delegates everything else to the integer.
    #
    def method_missing(meth, *args, &block)
      meth = meth.to_s
      if meth.ends_with?('=') && @keys.include?(meth[0, meth.size - 1].to_sym)
        self[meth[0, meth.size - 1].to_sym] = args.first
      elsif meth.ends_with?('?') && @keys.include?(meth[0, meth.size - 1].to_sym)
        self[meth[0, meth.size - 1].to_sym]
      else
        get_model_attr.send(meth.to_sym, *args, &block)
      end
    end
    
    ##
    # Delegates to integer
    #
    def ==(other)
      get_model_attr == other.to_i
    end

    ##
    # Delegates to integer
    #
    def eql?(other)
      get_model_attr.eql?(other.to_i)
    end
    
    ##
    # Delegates to integer
    #
    def is_a?(klass)
      get_model_attr.is_a?(klass) || self.is_a?(klass)
    end
  
    ##
    # Delegates to integer
    #
    def inspect
      get_model_attr.inspect
    end
    
    ##
    # Delegates to integer
    #
    def to_s
      get_model_attr.to_s
    end
    
    private
    def normalize_input(args)
      arg1 = args.first
      args = arg1.keys.select{|k| !!arg1[k]} if args1.is_a?(Hash)
      args.map{|v| v.to_sym}
    end
    
    def add_keys!(keys)
      keys = symbolize(keys.flatten)
    
      keys.each do |key|
        unless key_true?(key)
          set_model_attr(get_model_attr ? 
            get_model_attr + value_for(key) : 
            value_for(key))
        end
      end
      get_model_attr
    end
  
    def remove_keys!(keys)
      keys = symbolize(keys.flatten)
    
      keys.each do |key|
        if key_true?(key)
          set_model_attr(get_model_attr ? 
            get_model_attr - value_for(key) : 
            value_for(key))
        end
      end
      get_model_attr
    end
  
    def key_true?(key)
      key = key.to_sym
      get_model_attr ? (get_model_attr[@keys.index(key)] == 1) : false
    end
  
    def value_for(key)
      mapped_integer_for_key(key, @keys)
    end
  
    def get_model_attr
      @model[@attr_name]
    end
  
    def set_model_attr(value)
      @model[@attr_name] = value
    end
  end
end