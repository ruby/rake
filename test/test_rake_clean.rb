require File.expand_path('../helper', __FILE__)

class TestRakeClean < Rake::TestCase
  include Rake
  def test_clean
    # since other tests call Task.clear, this only works once
    if require('rake/clean')
      assert Task['clean'], "Should define clean"
      assert Task['clobber'], "Should define clobber"
      assert Task['clobber'].prerequisites.include?("clean"),
        "Clobber should require clean"
    end
  end
end
