require "erb"

module MRubyLicense
  module Internals
    refine ::Object do
      def fileset_list_under(basedir)
        [self].fileset_list_under(basedir)
      end

      def fileset_make_under(*dirs, prefix: nil)
        [self].fileset_make_under(*dirs, prefix: prefix)
      end
    end

    refine ::Array do
      def fileset_list_under(basedir)
        basedir = Pathname.new(basedir)
        alist = []
        _fileset_traverse_under(basedir, nil, nil, nil) do |path, entity|
          alist << entity if entity.respond_to?(:to_path)
          nil
        end
        alist
      end

      def fileset_make_under(basedir, *dirs, prefix: nil)
        basedir = Pathname.new(basedir)
        prefix = "#{prefix}:" if prefix
        alist = {}
        _fileset_traverse_under(basedir, dirs, prefix, alist) do |path, entity|
          case entity
          when nil
            nil
          when String
            entity
          when Proc, Method
            entity.call
          else # File, Pathname, StringIO, ...
            entity.read
          end
        end
        alist.empty? ? nil : alist
      end

      def _fileset_traverse_under(basedir, dirs, prefix, alist, &block)
        flatten.each do |entry|
          case entry
          when nil
          when Hash
            entry.each do |path, entity|
              case entity
              when Pathname
                _fileset_traverse_add(basedir, dirs, prefix, alist, basedir + path, basedir + entity, &block)
              else
                _fileset_traverse_add(basedir, dirs, prefix, alist, basedir + path, entity, &block)
              end
            end
          when String, Pathname
            _fileset_traverse_add(basedir, dirs, prefix, alist, basedir + entry, basedir + entry, &block)
          else
            _fileset_traverse_add(basedir, dirs, prefix, alist, basedir + entry, entry, &block)
          end
        end
      end

      def _fileset_traverse_add(basedir, dirs, prefix, alist, path, entity, &block)
        name = path.to_s.relative_path_under(basedir, *dirs)
        entity = String(yield path, entity)
        unless alist.nil? || entity.empty?
          key = "#{prefix}#{name}"
          raise "conflict file name - #{key} for #{basedir}" if alist.key?(key)
          alist[key] = entity
        end
      end
    end

    refine ::String do
      def relative_path_under(*dirs)
        dirs.each do |dir|
          return relative_path_from dir if start_with? File.join(dir, "/")
        end

        self
      end
    end

    refine ::Object do
      def dig(*)
        nil
      end
    end

    refine ::String do
      def to_html
        gsub(/"|'|&|<|>/, { '"' => "&quot;", "'" => "&apos;", "&" => "&amp;", "<" => "&lt;", ">" => "&gt;" })
      end

      def to_html_paragraph
        to_html.gsub(/^$/, "<br>")
      end
    end

    refine ::Object do
      def to_html_for_terms(indent: "", klass: nil, list: false, terms: false)
        case
        when terms
          %(<pre>\n#{String(self).chomp.to_html}\n</pre>)
        else
          String(self).to_html
        end
      end
    end

    refine ::Array do
      def to_html_for_terms(indent: "", klass: nil, list: false, terms: false)
        dest = ""
        case
        when list
          ii = indent + "  "
          dest << "<ul>\n"
          each_with_index do |e, i|
            dest << %(<li>#{e.to_html_for_terms(indent: ii + "  ", terms: terms)}</li>\n)
          end
          dest << "</ul>\n"
        else
          each_with_index do |e, i|
            dest << "\n"
            dest << "<hr>\n\n" if i > 0
            if e.dig("NAME") && e.dig("AUTHORS") && e.dig("LICENSES") && e.dig("TERMS")
              id = e.dig("NAME").gsub(/\W+/m, "-").to_html
              dest << %(<div id="#{id}">\n<h3>#{e.dig("NAME").to_html}</h3>\n\n)
            end
            dest << e.to_html_for_terms(klass: klass, indent: indent + "  ", terms: terms)
            dest << %(</div>\n) if id
          end
        end
        dest
      end
    end

    refine ::Hash do
      def to_html_for_terms(indent: "", klass: nil, list: false, terms: false)
        dest = %(<dl class="#{klass}">\n)
        ii = indent + "  "
        case
        when terms
          each_with_index do |(dt, dd), i|
            dest << "\n" if i > 0
            cls = dt.downcase.gsub(/\W+/, "-")
            dest << %(<dt class="path">#{dt.to_html}</dt>\n)
            dest << %(<dd class="entry">\n#{dd.to_html_for_terms(indent: ii + "  ", terms: true)}</dd>\n)
          end
        when self["TERMS"]
          each_with_index do |(dt, dd), i|
            dest << "\n" if i > 0
            cls = dt.downcase.gsub(/\W+/, "-")
            dest << %(<dt class="#{cls.to_html}">#{dt.to_html}</dt>\n)
            dest << %(<dd class="#{cls.to_html}">\n#{dd.to_html_for_terms(indent: ii + "  ", list: (dt == "AUTHORS" || dt == "LICENSES"), terms: (dt == "TERMS"))}</dd>\n)
          end
        else
          each_with_index do |(dt, dd), i|
            dest << "\n" if i > 0
            dest << %(<dt class="label">#{dt.to_html}</dt>\n)
            dest << %(<dd class="entity">\n#{dd.to_html_for_terms(indent: ii + "  ")}\n</dd>\n)
          end
        end
        dest << %(</dl>\n)
        dest
      end
    end

    refine ::MRuby::Build do
      def _initialize_terms
        @terms ||= []
      end
    end

    refine ::MRuby::Gem::Specification do
      def _initialize_terms
        @disable_license_export_as_html = false
        @disable_license_export_as_text = false
        @terms = []
        %w[LICENSE COPYRIGHT COPYING].product(%W[#{} .txt .md]) do |fn, ext|
          name = fn + ext
          if File.exist?("#{dir}/#{name}")
            @terms << name
            break
          end
        end
      end
    end

    refine MRubyLicense.singleton_class do
      def export_as_html(path, info)
        csspath = path.sub(/(?:\.html)?$/, ".css")
        cssbody = ERB.new(File.read(File.join(__dir__, "LICENSE.css.erb")), trim_mode: "%").result(binding)
        begin
          File.binwrite(csspath, cssbody, mode: File::CREAT | File::EXCL | File::WRONLY)
        rescue Errno::EEXIST
          nil
        end

        body = ERB.new(File.read(File.join(__dir__, "LICENSE.html.erb")), trim_mode: "%").result(binding)
        File.binwrite(path, body)

        path
      end

      def export_as_text(path, info)
        body = ERB.new(File.read(File.join(__dir__, "LICENSE.txt.erb")), trim_mode: "%").result(binding)
        File.binwrite(path, body)

        path
      end
    end
  end
end
