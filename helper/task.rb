require "yaml"
require "pathname"
require_relative "supplement"

using MRubyLicense
using MRubyLicense::Internals

desc "generate LICENSE.yml file for each targets"
task "license"

generator_task_trampoline = -> do
  build = MRuby::Build.current

  generator_task = ->(*a) do
    license_file = "#{build.build_dir}/LICENSE.yml"
    return nil if Rake::Task.task_defined?(license_file)

    if build.respond_to?(:products)
      build.products << license_file
    else
      task build.libmruby_static => license_file
    end

    task "license" => license_file

    coreterms = [MRubyLicense::CORE_LICENSE]
    coreterms << {
      "src/fmt_fp.c" => proc {
        path = File.join(MRUBY_ROOT, "src/fmt_fp.c")
        if File.exist?(path) && build.cc._try_compile(<<~'check-with-musl')
            #include <mruby.h>

            #if !defined(MRB_NO_FLOAT) && defined(MRB_WITHOUT_FLOAT)
            # define MRB_NO_FLOAT 1
            #endif

            #if !defined(MRB_NO_STDIO) && defined(MRB_DISABLE_STDIO)
            # define MRB_NO_STDIO 1
            #endif

            #if !defined(MRB_NO_FLOAT) && (defined(MRB_NO_STDIO) || defined(_WIN32) || defined(_WIN64))
              /* with musl */
            #else
            # error without musl
            #endif
          check-with-musl

          pattern = /Most code in this file originates from musl .*? OR OTHER DEALINGS IN THE SOFTWARE\.\n/m
          File.extract(path, pattern).gsub(/^ \*(?: |$)/, "") rescue nil # for pattern mismatch
        else
          nil
        end
      },
      "src/string.c" => proc {
        path = File.join(MRUBY_ROOT, "src/string.c")
        if File.exist?(path) && build.cc._try_compile(<<~'check-with-strtod')
            #include <mruby.h>

            #if defined(MRB_NO_FLOAT) || defined(MRB_WITHOUT_FLOAT)
            # error without strtod
            #endif
          check-with-strtod

          pattern = /Source code for the "strtod" library procedure\..*? \* express or implied warranty\.\n/m
          File.extract(path, pattern).gsub(/^ \*(?: |$)/, "") rescue nil # for pattern mismatch
        else
          nil
        end
      },
    }

    termfiles = []
    termfiles << coreterms.fileset_list_under(MRUBY_ROOT)
    termfiles << build.terms.fileset_list_under(build.build_dir)
    build.gems.each { |g|
      termfiles << File.join(g.dir, "mrbgem.rake")
      termfiles << g.terms.fileset_list_under(g.dir)
    }
    termfiles.flatten!
    termfiles.compact!

    file license_file => [__FILE__, ::MRUBY_CONFIG, *termfiles] do |t|
      _pp "GEN", t.name.relative_path

      info = {
        "about this file" => {
          "NOTICE AND DISCLAIMER" => <<~"NOTICE",
            This file is mechanically generated based on the mruby build configuration file.
            It is not guaranteed to cover all relevant license terms of the copyrighted work.
            If you suspect a deficiency license terms, please check to see if it is provided as a separate file and contact the software distributor.
          NOTICE
          "GENERATED WITH" => "https://github.com/dearblue/mruby-license",
          "GENERATED AT" => Time.now.strftime("%Y-%m-%dT00:00:00%z"), # ISO 8601
        },
        "mruby" => {
          "AUTHORS" => "mruby developers",
          "LICENSES" => "MIT",
          "TERMS" => coreterms.fileset_make_under(MRUBY_ROOT, prefix: "mruby")
        }
      }

      addterms = build.terms.fileset_make_under(build.build_dir, MRUBY_ROOT, prefix: "additional")
      info["additional terms by build_config"] = addterms if addterms

      if build.enable_gems?
        gems_info = []
        noterms = []

        build.gems.sort_by { |g| g.name }.each do |g|
          next if g.name == "mruby-license" && g.authors == "dearblue"

          gemterms = g.terms.fileset_make_under(g.dir, g.build_dir, MRUBY_ROOT, prefix: g.name)

          unless gemterms
            if g.core?
              g.supplement_license

              gemterms = g.terms.fileset_make_under(g.dir, g.build_dir, MRUBY_ROOT, prefix: g.name)
              gemterms = "same as mruby's license" unless gemterms
            else
              gemterms = "<<<FOR THE DETAILED LICENSE TERMS OF THIS GEM, PLEASE CHECK FILES DIRECTLY>>>"
              noterms << g
            end
          end

          gems_info << {
            "NAME" => g.name,
            "AUTHORS" => Array(g.authors).flatten.uniq,
            "LICENSES" => Array(g.licenses).flatten.uniq,
            "TERMS" => gemterms
          }
        end

        info["mruby gems"] = gems_info unless gems_info.empty?

        unless noterms.empty?
          if $stderr.tty? && RUBY_PLATFORM !~ /mswin|mingw/
            strong = "\e[7m"
            em = "\e[4m"
            clear = "\e[m"
          end
          m = "s" if noterms.size > 1
          $stderr.puts <<~WARNS
            #{strong}WARNING#{clear}: no LICENSE file#{m} in the following GEM#{m}:
            |
            #{noterms.map { |g| %(|\t%-23s\t%s) % [g.name, g.dir] }.join("\n")}
            |
            | LICENSE information can be added in the build_config file.
            | See "#{File.join(File.dirname(__dir__), "README.md")}" for more details.
          WARNS
        end
      end

      mkdir_p File.dirname(t.name)

      if build.license_export_as_html?
        MRubyLicense.export_as_html(t.name.sub(/(?:\.yml)?$/, ".html"), info)
      end

      if build.license_export_as_text?
        MRubyLicense.export_as_text(t.name.sub(/(?:\.yml)?$/, ".txt"), info)
      end

      File.binwrite(t.name, YAML.dump(info))
    end
  end

  generator_task
end

MRubyLicense.define_singleton_method(:create_generator_task, -> { generator_task_trampoline.call })
