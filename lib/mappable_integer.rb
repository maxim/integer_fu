module IntegerFu

  #  Cheat sheet
  #    000 0
  #    001 1
  #    010 2
  #    011 3
  #    100 4
  #    101 5
  #    110 6
  #    111 7
  #   1000 8
  #   1001 9
  #   1010 10
  #   1011 11
  #   1100 12
  #   1101 13
  #   1110 14
  #   1111 15

  class MappableInteger
    include Enumerable
    
    class << self
      def array_to_integer(array, keys)
        keys = symbolize(keys)
        array = symbolize(array)
        array.inject(0) do |sum, key|
          sum += (keys.index(key) ? 2**keys.index(key) : 0)
        end
      end
      
      def symbolize(array)
        array.map {|v| v.to_sym }
      end
    end
  
    def initialize(attr_name, parent_model, keys)
      @attr_name = attr_name.to_sym
      @model = parent_model
      @keys = self.class.symbolize(keys)
    end
    
    # ================================
    # Overriden operators and methods
    # ================================
    def [](*args)
      if args.first.is_a?(Numeric)
        get_model_attr[args.first]
      else
        args.all? { |key| key_true?(key) }
      end
    end
  
    def <<(*args)
      self + args
    end
  
    def +(*args)
      if args.first.is_a?(Numeric)
        get_model_attr + args.first
      else
        add_keys!(args)
      end
    end
  
    def -(*args)
      if args.first.is_a?(Numeric)
        get_model_attr - args.first
      else
        remove_keys!(args)
      end
    end
    
    # ================================
    # Delegated operators and methods
    # ================================
    def ==(other)
      get_model_attr == other.to_i
    end
    
    def eql?(other)
      get_model_attr.eql?(other.to_i)
    end
    
    def is_a?(klass)
      get_model_attr.is_a?(klass) || self.is_a?(klass)
    end
  
    def inspect
      get_model_attr.inspect
    end
    
    def to_s
      get_model_attr.to_s
    end
    
    # ================================
    # Additional conveniences
    # ================================
    def to_a
      @keys.select{ |k| key_true?(k) }
    end
  
    
    # Handle question-mark methods.
    # Delegate everything else to the actual integer.
    def method_missing(meth, *args, &block)
      meth = meth.to_s
      if meth.ends_with?('?') && @keys.include?(meth[0, meth.size - 1].to_sym)
        self[meth[0, meth.size - 1].to_sym]
      else
        get_model_attr.send(meth.to_sym, *args, &block)
      end
    end
    
    def each
      self.to_a.each do |el|
        yield(el)
      end
    end
  
    private
    def add_keys!(keys)
      keys = self.class.symbolize(keys.flatten)
    
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
      keys = self.class.symbolize(keys.flatten)
    
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
      key = key.to_sym
      @keys.index(key) ? 2**@keys.index(key) : 0
    end
  
    def get_model_attr
      @model[@attr_name]
    end
  
    def set_model_attr(value)
      @model[@attr_name] = value
    end
  end
end