# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vorhees}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Lee"]
  s.date = %q{2010-03-15}
  s.description = %q{An opinionated JSON socket server client and matchers}
  s.email = %q{david at davelee.com.au}
  s.extra_rdoc_files = ["README", "lib/vorhees/client.rb", "lib/vorhees/matchers.rb"]
  s.files = ["Gemfile", "Manifest", "README", "Rakefile", "lib/vorhees/client.rb", "lib/vorhees/matchers.rb", "spec/client_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "spec/usage_spec.rb", "vorhees.gemspec"]
  s.homepage = %q{http://github.com/davidlee/vorhees}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Vorhees", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{vorhees}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{An opinionated JSON socket server client and matchers}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
