#!/usr/bin/env ruby

require 'test/unit'
require 'rake/packagetask'

class TestPackageTask < Test::Unit::TestCase
  def test_create
    pkg = Rake::PackageTask.new("pkgr", "1.2.3") { |p|
      p.package_files << "install.rb"
      p.package_files.add(
	'[A-Z]*',
	'bin/**/*',
	'lib/**/*.rb',
	'test/**/*.rb',
	'doc/**/*',
	'build/rubyapp.rb',
	'*.blurb')
      p.package_files.exclude(/\bCVS\b/)
      p.package_files.exclude(/~$/)
      p.need_tar = true
      p.need_zip = true
    }
    assert_equal "pkg", pkg.package_dir
    assert pkg.package_files.include?("bin/rake")
    assert "pkgr", pkg.name
    assert "1.2.3", pkg.version
    assert Task[:package]
    assert Task["pkg/pkgr-1.2.3"]
    assert Task['pkg/pkgr-1.2.3.tgz']
    assert Task['pkg/pkgr-1.2.3.zip']
    assert Task[:clobber_package]
    assert Task[:repackage]
  end
end
