require_relative "extensions"
require_relative "supplement"
require_relative "task"

using MRubyLicense
using MRubyLicense::Internals

MRuby::Build.current.instance_eval do
  build = self
  build._initialize_terms
  build.gems.each do |g|
    g._initialize_terms
    g.terms_setup if g.respond_to?(:terms_setup)
  end
end

readme = File.read(File.join(File.dirname(__dir__), "README.md"))
MRubyLicense::VERSION = readme.scan(/^\s*[\-\*] version:\s*(\d+(?:\.\w+)+)/i).flatten&.[](-1)
