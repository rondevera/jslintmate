require 'rubygems'
require 'rspec/core/rake_task'

task :default => :spec

desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern   = Dir.glob('Tests/**/*_spec.rb').sort
  t.ruby_opts = ['-ISupport/lib:Tests']
  t.verbose   = true
end
