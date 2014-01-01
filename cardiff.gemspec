Gem::Specification.new do |s|
  s.name    = "cardiff"
  s.version = "0.0.1"
  s.summary = "A Ruby Diffing Library"
  s.author  = "Luke Gruber"

  s.files = Dir.glob("ext/**/*.{c,rb}") +
            Dir.glob("lib/**/*.rb")

  s.extensions << "ext/cardiff/extconf.rb"

  s.add_development_dependency "rake-compiler"
end
