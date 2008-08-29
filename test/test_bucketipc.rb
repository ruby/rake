
$LOAD_PATH.unshift(File.expand_path("#{File.dirname(__FILE__)}/../lib"))

require 'test/unit'
require 'comptree/bucket_ipc'

Thread.abort_on_exception = true

class BucketTest < Test::Unit::TestCase
  include CompTree::RetriableFork

  def each_bucket(num_buckets, &block)
    if HAVE_FORK
      CompTree::BucketIPC::Driver.new(num_buckets) { |buckets|
        buckets.each { |bucket|
          yield bucket
        }
      }
    end
  end

  def test_1_no_fork
    each_bucket(10) { |bucket|
      local = bucket.contents = :before
      bucket.contents = :after
      assert_equal(local, :before)
      assert_equal(bucket.contents, :after)
    }
  end

  def test_2_fork
    each_bucket(10) { |bucket|
      local = bucket.contents = :before
      process_id = fork {
        bucket.contents = :after
      }
      Process.wait(process_id)
      assert_equal(local, :before)
      assert_equal(bucket.contents, :after)
    }
  end

  def each_base_test
    [
     :test_1_no_fork,
     :test_2_fork,
    ].each { |method|
      yield method
    }
  end
  
  def test_3_thread
    each_base_test { |method|
      Thread.new {
        send(method)
      }.join
    }
  end

  def test_4_thread_flood
    each_base_test { |method|
      (0...10).map {
        Thread.new {
          send(method)
        }
      }.each { |thread|
        thread.join
      }
    }
  end
end

