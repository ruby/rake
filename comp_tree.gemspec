
Gem::Specification.new { |t|
  t.author = "James M. Lawrence"
  t.email = "quixoticsycophant@gmail.com"
  t.summary = "Parallel computation tree"
  t.name = "comp_tree"
  t.rubyforge_project = "comptree"
  t.homepage = "comptree.rubyforge.org"
  t.version = "0.5.0"
  t.description = "Build a computation tree and execute it with N " +
    "parallel threads.  Optionally fork computation nodes into new processes."

  t.files = %w{README} + Dir["lib/**/*.rb"] + Dir["test/**/*.rb"]

  rdoc_exclude = %w{
    test
    contrib
    install
    quix
    fork
    diagnostic
    algorithm
    bucket
    comptree
    comp_tree\.rb
  }
  t.has_rdoc = true
  t.extra_rdoc_files = %w{README}
  t.rdoc_options += [
    "--main",
    "README",
  ] + rdoc_exclude.inject(Array.new) { |acc, pattern|
    acc + ["--exclude", pattern]
  }
}
