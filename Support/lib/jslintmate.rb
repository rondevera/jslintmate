#!/usr/bin/env ruby

# Quick, simple JSLint in TextMate. Hurt your feelings in style.
# (JSLint.com is a powerful JS code quality tool.)

# Usage (in a TextMate bundle):
#
#   ruby '/path/to/jslintmate.rb' <options>
#
# Options:
#
#   --linter                'jslint' (default) or 'jshint'
#   --linter-file           '/path/to/jslint.js' or '/path/to/jshint.js'
#   --linter-options        Format: 'option1=value1,option2=value'
#   --linter-options-file   '/path/to/config/jslint.yml'
#
# Options precedence:
#
#   1.  Highest precedence: In-file options, e.g.,
#       `/*jslint browser: true, ... */`
#   2.  Options file (via `--linter-options-file`)
#   3.  Custom bundle preferences (via `--linter-options`)
#   4.  Default bundle preferences (via `JSLintMate::Linter.default_options`)
#
# To update jslint.js and jshint.js:
#
#   cd /path/to/JSLintMate.tmbundle/Support/lib/
#   curl -o jslint.js http://www.jslint.com/fulljslint.js
#   curl -o jshint.js http://jshint.com/jshint.js

$LOAD_PATH << File.join(ENV['TM_BUNDLE_SUPPORT'], 'lib')
require 'cgi'
require 'erb'
require 'jslintmate/linter'

module JSLintMate
  def self.version
    @version ||= begin
      File.read(File.join(JSLintMate.bundle_path, 'VERSION')).strip
    end
  end

  def self.args_to_hash(args_string)
    # Converts `args_string` (of the format `--foo=x --bar=y`) to a hash.

    args_string.inject({}) do |hsh, s|
      k, v = s.split('=', 2)
      k.sub!(/^--/, '')
      hsh.merge(k => v)
    end
  end

  def self.lib_path(*args)
    # Usage:
    #
    #   lib_path          # => /path/to/JSLintMate.tmbundle/Support/lib
    #   lib_path('x.js')  # => /path/to/JSLintMate.tmbundle/Support/lib/x.js

    dirs = ['lib'] << args
    File.join(bundle_path, 'Support', *dirs)
  end

  def self.bundle_path
    unless @bundle_path
      user_bundle_path      = ENV['TM_BUNDLE_PATH'].dup
      pristine_bundle_path  = user_bundle_path.sub('TextMate/Bundles',
                                'TextMate/Pristine Copy/Bundles')
      long_bundle_name      = 'JavaScript JSLintMate.tmbundle'
      short_bundle_name     = 'JSLintMate.tmbundle'
      long_bundle_rxp       = %r{/#{Regexp.escape long_bundle_name}$}
      short_bundle_rxp      = %r{/#{Regexp.escape short_bundle_name}$}

      paths = [
        pristine_bundle_path.
          sub(long_bundle_rxp, "/#{short_bundle_name}"),
          # => .../TextMate/Pristine Copy/Bundles/JSLintMate.tmbundle
        pristine_bundle_path.
          sub(short_bundle_rxp, "/#{long_bundle_name}"),
          # => .../TextMate/Pristine Copy/Bundles/JavaScript JSLintMate.tmbundle
        user_bundle_path.
          sub(long_bundle_rxp, "/#{short_bundle_name}"),
          # => .../TextMate/Bundles/JSLintMate.tmbundle
        user_bundle_path.
          sub(short_bundle_rxp, "/#{long_bundle_name}")
          # => .../TextMate/Bundles/JavaScript JSLintMate.tmbundle
      ]
      @bundle_path = paths.detect { |path| File.directory?(path) }
    end

    @bundle_path
  end

  def self.html
    File.read lib_path('jslintmate.html.erb')
  end

  def self.css
    File.read lib_path('jslintmate.css')
  end

  def self.js
    File.read lib_path('jslintmate.js')
  end

  def self.link_to_jslintmate
    %{
      <a href="https://github.com/rondevera/jslintmate" class="info"
        title="More info on JSLintMate #{version}">info</a>
    }.strip.split.join(' ')
  end

end # module JSLintMate



# Prepare `linter` instance
args   = JSLintMate.args_to_hash(ARGV)
linter = JSLintMate::Linter.new(
  :key      => args['linter'],
  :path     => args['linter-file'],
  :options  => args['linter-options'] || JSLintMate::Linter.default_options,
  :options_filepath => args['linter-options-file']
)
filepath = ENV['TM_FILEPATH']

if filepath
  problems_count = 0

  # Prepare linter options
  linter.reverse_merge_options_from_file!

  # Prepare OS X's JSC
  # Note: With some hacking, this can probably be made to work with Rhino
  # (Mozilla's open-source JS engine). Reference:
  # <http://www.phpied.com/installing-rhino-on-mac/>
  jsc   = JSLintMate.lib_path('jsc.js')
  cmd   = '/System/Library/Frameworks/JavaScriptCore.framework/' <<
           %{Versions/A/Resources/jsc "#{linter.path}" "#{jsc}" -- } <<
           %{"$(cat "#{filepath}")"}
  cmd   << %{ "#{linter.options_string}"} if linter.options
  lint  = `#{cmd}` # Find problems

  # Format problems
  lint.gsub!(/^(Lint at line )(\d+)(.+?:)(.+?)\n(?:(.+?)\n\n)?/m) do
    line, char, desc, code = $2, $3, $4, $5

    line = (line.to_i - 1).to_s
    char = (char.scan(/\d+/)[0].to_i - 1).to_s
    line_uri = "txmt://open?url=file://#{filepath}" <<
               "&line=#{CGI.escapeHTML(line)}&column=#{CGI.escapeHTML(char)}"
    desc = %{<span class="desc">#{CGI.escapeHTML(desc).strip}</span>} if desc
    loc  = %{<span class="location">#{
              CGI.escapeHTML("Line #{line}, character #{char}")}</span>}
    code = %{<pre>#{CGI.escapeHTML(code).strip}</pre>} if code

    if code
      problems_count += 1
      %{<li><a href="#{line_uri}">#{loc} #{desc} #{code}</a></li>}
    else
      %{<li class="alert">#{loc} #{desc}</li>}
    end
  end

  if lint =~ /No problems found/
    # Douglas Crockford would be so proud.
    result = %{
      <header>
        <span class="desc">Lint-free!</span>
        <span class="filepath">#{filepath}</span>
        #{JSLintMate.link_to_jslintmate}
      </header>
      <p class="success">Lint-free!</p>
    }
  else
    result = %{
      <header>
        <span class="desc">Problem#{'s' if
          problems_count > 1} found in:</span>
        <span class="filepath">#{filepath}</span>
        #{JSLintMate.link_to_jslintmate}
      </header>
      <ul class="problems">#{lint}</ul>
    }
  end
else # !filepath
  result = %{
    <header class="alert">
      <span class="desc">Oops!</span>
      #{JSLintMate.link_to_jslintmate}
    </header>
    <p class="alert">
      Please save this file before
      #{linter} can hurt your feelings.
    </p>
  }
end

result.strip!

template = ERB.new(JSLintMate.html)
print template.result(binding)
