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

namespace :diffutils do
  desc 'Clean all diffutils objects'
  task :clean do
    in_diffutils_dir do
      system('make clean')
    end
  end

  desc 'Run distclean in diffutils dir'
  task :distclean do
    in_diffutils_dir do
      system('make distclean')
    end
  end

  desc 'Run configure for diffutils and create diffutils project-level Makefile'
  task :configure do
    in_diffutils_dir do
      system('configure')
    end
  end

  desc 'Clean all diffutils objects and recreate diffutils project-level Makefile'
  task :remake => [:distclean, :configure] do
    in_diffutils_dir do
      system('make')
    end
  end
end

desc 'Clobber all objects, recreate diffutils makefiles, compile ruby extension and run tests'
task :fresh_compile do
  Rake.application['clobber'].invoke
  Rake.application['diffutils:remake'].invoke
  Rake.application['compile'].invoke
  Rake.application['test'].invoke
end

def in_diffutils_dir
  Dir.chdir(File.expand_path('../ext/vendor/diffutils', __FILE__)) do
    yield
  end
end
