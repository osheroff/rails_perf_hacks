Gem::Specification.new do |s|
  s.name = %q{rails_perf_hacks}
  s.version = "0.0.2"

  s.authors = ["Ben Osheroff"]
  s.date = %q{2011-10-28}
  s.description = %q{}
  s.email = ["ben@gimbo.net"]
  s.files = [
    "ext/**",
  ]
  s.require_paths = ["ext", "lib"]
  s.extensions << 'ext/extconf.rb'

  s.summary = %q{yup}

  s.add_runtime_dependency("activesupport", "~> 2.3.14")
end

