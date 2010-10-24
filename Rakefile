require 'bundler'
Bundler.setup
Bundler.require :default, :development

require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'fileutils'
include FileUtils

# copied from EventMachine.
MAKE = ENV['MAKE'] || if RUBY_PLATFORM =~ /mswin/ # mingw uses make.
  'nmake'
else
  'make'
end

# Default Rake task is compile
task :default => :compile

# RDoc
Rake::RDocTask.new(:rdoc) do |task|
  task.rdoc_dir = 'doc'
  task.title    = 'EventMachine::HttpRequest'
  task.options = %w(--title HttpRequest --main README.md --line-numbers)
  task.rdoc_files.include(['lib/**/*.rb'])
  task.rdoc_files.include(['README.md', 'LICENSE'])
end

# Rebuild parser Ragel
task :ragel do
  Dir.chdir "ext/http11_client" do
    target = "http11_parser.c"
    File.unlink target if File.exist? target
    sh "ragel http11_parser.rl | rlgen-cd -G2 -o #{target}"
    raise "Failed to build C source" unless File.exist? target
  end
end

require 'rspec/core/rake_task'
Rspec::Core::RakeTask.new(:spec)

def make(makedir)
  Dir.chdir(makedir) { sh MAKE }
end

def extconf(dir)
  Dir.chdir(dir) { ruby "extconf.rb" }
end

def setup_extension(dir, extension)
  ext = "ext/#{dir}"
  ext_so = "#{ext}/#{extension}.#{Config::MAKEFILE_CONFIG['DLEXT']}"
  ext_files = FileList[
    "#{ext}/*.c",
    "#{ext}/*.h",
    "#{ext}/extconf.rb",
    "#{ext}/Makefile",
    "lib"
  ]

  task "lib" do
    directory "lib"
  end

  desc "Builds just the #{extension} extension"

  mf = (extension + '_makefile').to_sym

  task mf do |t|
    extconf "#{ext}"
  end

  task extension.to_sym => [mf] do
    make "#{ext}"
    cp ext_so, "lib"
  end
end

setup_extension("buffer", "em_buffer")
setup_extension("http11_client", "http11_client")

task :compile => [:em_buffer, :http11_client]

CLEAN.include ['build/*', '**/*.o', '**/*.so', '**/*.a', '**/*.log', 'pkg']
CLEAN.include ['ext/buffer/Makefile', 'lib/em_buffer.*', 'lib/http11_client.*']

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "em-http-request"
    gemspec.summary = "EventMachine based, async HTTP Request interface"
    gemspec.description = gemspec.summary
    gemspec.email = "ilya@igvita.com"
    gemspec.homepage = "http://github.com/igrigorik/em-http-request"
    gemspec.authors = ["Ilya Grigorik"]
    gemspec.required_ruby_version = ">= 1.8.6"
    gemspec.extensions = ["ext/buffer/extconf.rb" , "ext/http11_client/extconf.rb"]
    gemspec.add_dependency('eventmachine', '>= 0.12.9')
    gemspec.add_dependency('addressable', '>= 2.0.0')
    gemspec.rubyforge_project = "em-http-request"
    gemspec.files = FileList[`git ls-files`.split]
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
