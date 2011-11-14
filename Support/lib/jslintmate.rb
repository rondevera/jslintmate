#!/usr/bin/env ruby

# Quick, simple JSLint in TextMate. Hurt your feelings in style.
# (JSLint.com is a powerful JS code quality tool. JSHint.com is a
# community-driven project based on JSLint, and doesn't hurt your feelings so
# much.)
#
# Usage (in a TextMate bundle):
#
#   ruby '/path/to/jslintmate.rb' <options>
#
# Options:
#
#   --file                  '/path/to/my-file.js'; defaults to
#                           `ENV['TM_FILEPATH']`
#   --linter                'jslint' (default) or 'jshint'
#   --linter-file           '/path/to/jslint.js' or '/path/to/jshint.js'
#   --linter-options        Format: 'option1:value1,option2:value'
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
#   curl -o jslint.js http://jslint.com/jslint.js
#   curl -o jshint.js http://jshint.com/jshint.js

$LOAD_PATH << File.join(ENV['TM_BUNDLE_SUPPORT'] || 'Support', 'lib')
require 'cgi'
require 'erb'
require 'jslintmate/lint_error'
require 'jslintmate/linter'

module JSLintMate
  def self.version
    @version ||= begin
      version_filepath = File.join(JSLintMate.bundle_path, 'VERSION')
      File.read(version_filepath).strip
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
      user_bundle_path      = (ENV['TM_BUNDLE_PATH'] || '.').dup
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

  def self.html ; File.read lib_path('jslintmate.html.erb') ; end
  def self.css  ; File.read lib_path('jslintmate.css')      ; end
  def self.js   ; File.read lib_path('jslintmate.js')       ; end

  def self.link_to_jslintmate
    %{
      <a href="https://github.com/rondevera/jslintmate" class="info"
        title="More info on JSLintMate #{version}">info</a>
    }.strip.split.join(' ')
  end

  def self.error_to_html(error_data)
    # `error_data` is a hash whose keys should match
    # `JSLintMate::LintError#initialize`.
    #
    # Returns an HTML `<li>` wrapper that represents the given error data.

    lint_error = JSLintMate::LintError.new(error_data)
    lint_error_html = lint_error.to_html

    if lint_error.code == ''
      # Use special formatting for stoppage alerts
      %{<li class="alert">#{lint_error_html}</li>}
    else
      %{<li>#{lint_error_html}</li>}
    end
  end

end # module JSLintMate



# Prepare `linter` instance
args   = JSLintMate.args_to_hash(ARGV)
linter = JSLintMate::Linter.new(
  :key  => args['linter'],
  :path => args['linter-file'],
  :options_from_bundle => args['linter-options'],
  :config_file_path    => args['linter-options-file']
)
filepath = args['file'] || ENV['TM_FILEPATH']

if filepath
  problems_count = 0

  # Get lint data
  lint = linter.get_lint_for_filepath(filepath)

  # Format errors, if any
  lint.gsub!(/^(Lint at line )(\d+)(.+?:)(.+?)\n(?:(.+?))?$/) do
    line, column, desc, code = $2, $3, $4, $5

    # Increment problem counter unless this error is actually an alert, which
    # has no code snippet
    problems_count += 1 if code

    JSLintMate.error_to_html(
      :filepath => filepath,
      :line     => line,
      :column   => column,
      :desc     => desc,
      :code     => code
    )
  end

  # Format unused variables, if any
  lint.gsub!(/^Unused variable at line (\d+): (.+?)$/) do
    line, code = $1, $2

    problems_count += 1

    JSLintMate.error_to_html(
      :filepath => filepath,
      :line     => line,
      :code     => code,
      :desc     => 'Unused variable.'
    )
  end

  if problems_count == 0
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
