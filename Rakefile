require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'fileutils'
include FileUtils

# Default Rake task is compile
task :default => :compile

# RDoc
Rake::RDocTask.new(:rdoc) do |task|
  task.rdoc_dir = 'doc'
  task.title    = 'EventMachine::HttpClient'
  task.options = %w(--title HttpClient --main README --line-numbers)
  task.rdoc_files.include(['lib/**/*.rb'])
  task.rdoc_files.include(['README', 'LICENSE'])
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

def make(makedir)
  Dir.chdir(makedir) { sh 'make' }
end

def extconf(dir)
  Dir.chdir(dir) { ruby "extconf.rb" }
end

def setup_extension(dir, extension)
  ext = "ext/#{dir}"
  ext_so = "#{ext}/#{extension}.#{Config::CONFIG['DLEXT']}"
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
  task extension.to_sym => ["#{ext}/Makefile", ext_so ]

  file "#{ext}/Makefile" => ["#{ext}/extconf.rb"] do
    extconf "#{ext}"
  end

  file ext_so => ext_files do
    make "#{ext}"
    cp ext_so, "lib"
  end
end

setup_extension("buffer", "em_buffer")
setup_extension("http11_client", "http11_client")

task :compile => [:em_buffer, :http11_client]

CLEAN.include ['build/*', '**/*.o', '**/*.so', '**/*.a', '**/*.log', 'pkg']
CLEAN.include ['ext/buffer/Makefile', 'lib/em_buffer.*', 'lib/http11_client.*']
