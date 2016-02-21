Gem::Specification.new do |s|
  s.name = "class_state"
  s.version = '0.1.0'
  s.date = '2016-02-21'

  s.files = `git ls-files`.split($/)
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake', '~> 10.5'
  s.add_development_dependency 'rspec', '~> 3.3'

  s.author = "Mark van de Korput"
  s.email = "dr.theman@gmail.com"
  s.description = %q{A ruby class for managing states class-states}
  s.summary = %q{Provides logic and a framework for thinking about the state of your classes}
  s.homepage = %q{https://github.com/markkorput/class_state}
  s.license = "MIT"
end
