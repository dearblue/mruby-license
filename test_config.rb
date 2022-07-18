#!ruby

require "stringio"

MRuby::Lockfile.disable rescue nil

MRuby::Build.new("host", File.join(__dir__, "build")) do |conf|
  conf.toolchain "clang"

  conf.enable_debug
  conf.disable_presym rescue nil

  conf.gem core: "mruby-random"
  conf.gem core: "mruby-io" rescue nil
  conf.gem __dir__

  conf.terms << { "test terms1" => "test1" }
  conf.terms << { "test terms2" => "test2", "test terms3" => StringIO.new("test3") }
end
