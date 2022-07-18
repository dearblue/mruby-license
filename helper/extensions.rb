require "pathname"
require "tmpdir"
require_relative "mruby-source"
require_relative "internals"

module MRubyLicense
  CORE_LICENSE = (MRUBY_RELEASE_NO > 20000) ? "LICENSE" : "MITL"

  refine ::File.singleton_class do
    def extract(path, pattern, *args, mode: "rt", **opts)
      # NOTE: In Cygwin, explicit text mode specification is required for reading
      src = File.read(path, *args, mode: mode, **opts)
      src.slice(pattern) or raise "pattern mismatch - #{path}"
    end
  end

  refine ::MRuby::Command do
    def _try_compile(code)
      Dir.mktmpdir("mruby") do |dir|
        obj = File.join(dir, "obj#{build.exts.object}")
        src = File.join(dir, "input.c")
        File.write(src, code)
        params = { flags: all_flags, infile: filename(src), outfile: filename(obj) }
        sh "#{build.filename(command)} #{compile_options % params}", out: File::NULL, err: File::NULL do |ok, *|
          ok
        end
      end
    end
  end
end

using MRubyLicense
using MRubyLicense::Internals

module MRubyLicense
  module Build
    attr_accessor :terms

    def initialize(*args, **kw, &block)
      _initialize_terms
      super(*args, **kw, &block)
    end

    unless MRUBY_RELEASE_NO >= 20000
      def libmruby_static
        libfile("#{build_dir}/lib/libmruby")
      end
    end

    def disable_license_export_as_html
      @disable_license_export_as_html = true
      self
    end

    def disable_license_export_as_text
      @disable_license_export_as_text = true
      self
    end

    def license_export_as_html?
      !@disable_license_export_as_html
    end

    def license_export_as_text?
      !@disable_license_export_as_text
    end
  end

  module Gem
    module Specification
      attr_accessor :terms

      def setup
        orig = @initializer
        tempinit = proc {
          @initializer = orig if @initializer == tempinit
          _initialize_terms
          instance_eval(&orig)
          terms_setup if respond_to?(:terms_setup)
        }
        @initializer = tempinit
        super
      ensure
        @initializer = orig if tempinit && @initializer == tempinit
      end

      def extract_text(path, *rest, **kw, &b)
        File.extract(File.join(self.dir, path), *rest, **kw, &b)
      end

      unless ::MRuby::Gem::Specification.method_defined?(:core?)
        def core?
          File.dirname(self.dir) == File.join(MRUBY_ROOT, "mrbgems")
        end
      end
    end
  end
end

MRuby::Build.prepend MRubyLicense::Build
MRuby::Gem::Specification.prepend MRubyLicense::Gem::Specification
