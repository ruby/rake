$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'quix/config'
require 'quix/kernel'

if RUBY_VERSION >= "1.8.7"
  require 'test/unit'
  require 'quix/module'

  class TestPrivate < Test::Unit::TestCase
    BODY = %{
      def f ; end
      
      private {
        def g ; end
        def h ; end
      }
      
      def i ; end
  
      private {
        def j ; end
      }
        
      def k ; end
  
      private {
      }
  
      def l ; end
  
      def m ; end
      def n ; end
      private :m, :n
  
      def o ; end
    }
  
    class A
      eval(BODY)
    end

    module B
      eval(BODY)
    end

    class C
      include B
    end

    def test_1
      [A, C].map { |klass| klass.new }.each { |t|
        assert_nothing_raised { t.f }
        assert_raises(NoMethodError) { t.g }
        assert_raises(NoMethodError) { t.h }
        assert_nothing_raised { t.i }
        assert_raises(NoMethodError) { t.j }
        assert_nothing_raised { t.k }
        assert_nothing_raised { t.l }
        assert_raises(NoMethodError) { t.m }
        assert_raises(NoMethodError) { t.n }
        assert_nothing_raised { t.o }
      }
    end

    def test_2
      added = []
      Class.new {
        singleton_class.instance_eval {
          define_method(:method_added) { |name|
            added << name
          }
        }
        
        private {
          def f ; end
        }
        
        def g ; end
      }
      assert_equal([:f, :g], added)
    end
  end
end
  
