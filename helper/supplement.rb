require_relative "extensions"

using MRubyLicense
using MRubyLicense::Internals

module MRubyLicense
  module Supplement
    COREGEMS = {
      "mruby-errno" => ->(g) {
        pat = /Copyright \(c\) 2013 Internet Initiative Japan Inc\..*?DEALINGS IN THE SOFTWARE\.\n/m
        g.terms << { "README.md" => g.extract_text("README.md", pat).gsub(/ +$/, "") }
      },
      "mruby-io" => ->(g) {
        pat = /Copyright \(c\) 2013 Internet Initiative Japan Inc\..*?DEALINGS IN THE SOFTWARE\.\n/m
        g.terms << { "README.md" => g.extract_text("README.md", pat).gsub(/ +$/, "") }
      },
      "mruby-pack" => ->(g) {
        pat = /Copyright \(c\) 2012 Internet Initiative Japan Inc\..*?DEALINGS IN THE SOFTWARE\.\n/m
        g.terms << { "README.md" => g.extract_text("README.md", pat).gsub(/ +$/, "") }
      },
      "mruby-random" => ->(g) {
        pat = /Copyright \(C\) 1997 - 2016, Makoto Matsumoto and Takuji Nishimura,.*?SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE\.\n/m
        g.terms << { "MAIN" => "same as mruby's license" }
        g.terms << { "src/mt19937ar.c" => g.extract_text("src/mt19937ar.c", pat).gsub(/^\s*\*+ */, "").gsub(/ +$/, "") } rescue nil
      },
      "mruby-sleep" => ->(g) {
        pat = /Copyright \(c\) mod_mruby developers 2012-.*?SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE\.\n/m
        src = File.join(g.dir, s = "src/sleep.c")
        src = File.join(g.dir, s = "src/mrb_sleep.c") unless File.exist?(src)
        g.terms << { s => File.extract(src, pat).gsub(/^\s*\*+ ?/, "").gsub(/ +$/, "") }
      },
      "mruby-socket" => ->(g) {
        pat = /Copyright \(c\) 2013 Internet Initiative Japan Inc\..*?DEALINGS IN THE SOFTWARE\.\n/m
        g.terms << { "README.md" => g.extract_text("README.md", pat).gsub(/ +$/, "") }
      },
    }
  end

  refine ::MRuby::Gem::Specification do
    def supplement_license
      if core?
        n0 = self.name
        Supplement::COREGEMS.each_pair do |n, act|
          if n == n0
            act.call(self)
            break
          end
        end
      end
    end
  end
end
