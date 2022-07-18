begin
  require "mruby/source"
rescue LoadError
  $: << File.join(MRUBY_ROOT, "lib")
  begin
    require "mruby/source"
  rescue LoadError
    nil
  end
end

module MRubyLicense
  if defined?(MRuby::Source::MRUBY_RELEASE_NO)
    MRUBY_RELEASE_NO = ::MRuby::Source::MRUBY_RELEASE_NO
  else
    verfile = Pathname(MRUBY_ROOT) + "include/mruby/version.h"
    MRUBY_RELEASE_NO = verfile.file? ? 10100 : 10000
  end
end
