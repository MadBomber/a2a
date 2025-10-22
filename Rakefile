# frozen_string_literal: true

require 'bundler/audit/task'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yaml'
require 'yard/rake/yardoc_task'
require 'yard-junk/rake'
require 'yardstick/rake/measurement'
require 'yardstick/rake/verify'

yardstick_options = YAML.load_file('.yardstick.yml')

Bundler::Audit::Task.new

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

YARD::Rake::YardocTask.new
YardJunk::Rake.define_task
Yardstick::Rake::Measurement.new(:yardstick_measure, yardstick_options)
Yardstick::Rake::Verify.new

task default: %i[test]

# Remove the report on rake clobber
CLEAN.include('measurements', 'doc', '.yardoc', 'tmp')

desc 'Test and perform security and documentation audits'
task qa: %w[yard:junk verify_measurements bundle:audit]
