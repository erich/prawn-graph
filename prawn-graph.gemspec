# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{prawn-graph}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ryan Stenhouse"]
  s.date = %q{2010-02-26}
  s.description = %q{  An extension to Prawn that provides the ability to draw basic graphs and charts natively in your PDFs.
}
  s.email = %q{ ryan@ryanstenhouse.eu}
  s.extra_rdoc_files = ["README.markdown"]
  s.files = ["lib/prawn/graph/bar.rb", "lib/prawn/graph/base.rb", "lib/prawn/graph/chart.rb", "lib/prawn/graph/errors.rb", "lib/prawn/graph/grid.rb", "lib/prawn/graph/line.rb", "lib/prawn/graph/themes/37signals.yml", "lib/prawn/graph/themes/keynote.yml", "lib/prawn/graph/themes/monochome.yml", "lib/prawn/graph/themes/odeo.yml", "lib/prawn/graph/themes.rb", "lib/prawn/graph.rb", "Rakefile", "README.markdown"]
  s.homepage = %q{http://ryanstenhouse.eu}
  s.rdoc_options = ["--title", "Prawn Documentation", "--main", "README", "-q"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{prawn}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{An extension to Prawn that provides the ability to draw basic graphs and charts natively in your PDFs.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<prawn>, [">= 0"])
    else
      s.add_dependency(%q<prawn>, [">= 0"])
    end
  else
    s.add_dependency(%q<prawn>, [">= 0"])
  end
end
