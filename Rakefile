require 'rake/testtask'
require 'rake/extensiontask'

task :default => [:test]

desc 'Run all tests (default)'
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/**/*_test.rb'].to_a
end

spec = Gem::Specification.load('cardiff.gemspec')
Rake::ExtensionTask.new('cardiff', spec) do |ext|
  ext.name = 'cardiff_gnu_diff'
end
