module IntegerFu
  module Helpers
    module_function
    
    def raise_undefined_key_error(key)
      raise IntegerFu::IntegerFuError, "Attempt to access undefined key \"#{key}\"."
    end
    
    def symbolize(array)
      array.map{|v| v.to_sym}
    end
  
    def array_to_integer_with_keys(array, *keys)
      set_keys = symbolize(keys.flatten)
      all_keys = symbolize(array)
      set_keys.inject(0) do |sum, set_key|
        sum += mapped_integer_for_key(set_key, all_keys)
      end
    end
  
    def mapped_integer_for_key(key, array)
      key = key.to_sym
      all_keys = symbolize(array)
      all_keys.index(key) ? 2**all_keys.index(key) : 0
    end
  
    def keys_with_truthy_values(hash)
      hash.keys.select{|k| !!hash[k]}
    end
  end
end