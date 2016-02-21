require 'rdoc/task'
require "rspec/core/rake_task"

task :default => :rspec do; end

desc "Run all specs"
RSpec::Core::RakeTask.new('rspec') do |t|
  t.pattern = 'spec/**/*_spec.rb'
end
