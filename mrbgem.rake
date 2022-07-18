require_relative "helper/license"

generator_task = MRubyLicense.create_generator_task

if ENV["MRUBY_LICENSE_GEM_HIDDEN"].to_i > 0
  generator_task.call
else
  MRuby::Gem::Specification.new("mruby-license") do |s|
    s.summary = "LICENSE collector for mruby"
    s.version = MRubyLicense::VERSION if MRubyLicense::VERSION
    s.license = "CC0"
    s.author  = "dearblue"
    s.homepage = "https://github.com/dearblue/mruby-license"
    s.instance_eval(&generator_task)
  end
end
