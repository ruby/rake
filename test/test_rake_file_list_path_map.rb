# frozen_string_literal: false
require File.expand_path("../helper", __FILE__)

class TestRakeFileListPathMap < Rake::TestCase
  def test_file_list_supports_pathmap
    assert_equal ["a", "b"], FileList["dir/a.rb", "dir/b.rb"].pathmap("%n")
  end

  def test_file_list_supports_pathmap_with_a_block
    mapped = FileList["dir/a.rb", "dir/b.rb"].pathmap("%{.*,*}n") do |name|
      name.upcase
    end
    assert_equal ["A", "B"], mapped
  end
end
