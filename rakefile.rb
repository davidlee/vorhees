require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'fileutils'
begin
  require 'cucumber/rake/task'
rescue LoadError
  puts "cucumber is not installed."
end

require '.bundle/environment'
Bundler.setup()

if defined? Cucumber
  namespace :features do  
    Cucumber::Rake::Task.new(:all) do |t|
      t.cucumber_opts = %w{--format pretty --color}
    end
  end
  task :features => 'features:all'
end

namespace :spec do
  desc "Run the code examples in spec/*"
  Spec::Rake::SpecTask.new(:all) do |t|
    t.spec_opts = ['-c', '--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
    t.spec_files = FileList["spec/**/*_spec.rb"]
  end
  
  Dir['spec/**'].select {|f| File.directory? f }.map {|f| File.split(f).last }.each do |folder|
    desc "Run the code examples in spec/#{folder}"
    Spec::Rake::SpecTask.new(folder.to_sym) do |t|
      t.spec_opts = ['-c', '--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
      t.spec_files = FileList["spec/#{folder}/*_spec.rb"]
    end
  end
end

task :spec    => "spec:all"
task :default => :spec
