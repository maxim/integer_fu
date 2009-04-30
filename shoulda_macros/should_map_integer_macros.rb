module ShouldMapIntegerMacros
  def should_map_integer(integer_name)
    klass = self.name.gsub(/Test$/, '').constantize

    context "#{klass}" do
      should "map integer #{integer_name}" do
        assert_equal IntegerFu::MappableInteger, klass.new.send(integer_name).class
      end
    end
  end
end

class ActiveSupport::TestCase
  extend ShouldMapIntegerMacros
end