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

$LOAD_PATH << File.expand_path(
  File.join(ENV['TM_BUNDLE_SUPPORT'] || 'Support', 'lib'))
require 'erb'
require 'jslintmate/lint_error'
require 'jslintmate/linter'

module JSLintMate
  WEBSITE_URL = 'http://rondevera.github.com/jslintmate'

  def self.version
    @version ||= begin
      version_filepath =
        File.expand_path(File.join(JSLintMate.bundle_path, 'VERSION'))
      File.read(version_filepath).strip
    end
  end

  def self.args(args_string)
    # Returns a hash of arguments based on `args_string`, the bundle's
    # preferences, and the bundle's defaults.

    args = JSLintMate.args_to_hash(args_string)
    use_jshint = args['linter'] == 'jshint'

    # Merge with defaults
    args['linter-file'] ||= use_jshint ?
      ENV['TM_JSLINTMATE_JSHINT_FILE'].dup :
      ENV['TM_JSLINTMATE_JSLINT_FILE'].dup
    args['linter-options-file'] ||= use_jshint ?
      ENV['TM_JSLINTMATE_JSHINT_OPTIONS_FILE'].dup :
      ENV['TM_JSLINTMATE_JSLINT_OPTIONS_FILE'].dup

    # Expand file paths
    args['linter-file'] = JSLintMate.expand_path(args['linter-file'])
    args['linter-options-file'] =
      JSLintMate.expand_path(args['linter-options-file'])

    args
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
    File.expand_path(File.join(bundle_path, 'Support', *dirs))
  end

  def self.bundle_path
    @bundle_path ||= begin
      user_bundle_path      = (File.join(ENV['TM_BUNDLE_SUPPORT'], '..') || '.').dup
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
      paths.detect { |path| File.directory?(File.expand_path(path)) }
    end
  end

  def self.html ; File.read lib_path('jslintmate', 'main.html.erb') ; end
  def self.css  ; File.read lib_path('jslintmate', 'main.css')      ; end
  def self.js
    File.read(lib_path('jslintmate', 'main.js')) <<
    File.read(lib_path('jslintmate', 'version.js'))
  end

  def self.link_to_website
    %{
      <a href="#{WEBSITE_URL}" class="info"
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

  def self.expand_path(path)
    # Converts a relative path (e.g., `~/.jslintrc`,
    # `$TM_PROJECT_DIRECTORY/config/jslint.yml`) to an absolute path (e.g.,
    # `/Users/<username>/.jslintrc`,
    # `/Users/<username>/Projects/<project>/config/jslint.yml`).

    %w[
      TM_BUNDLE_SUPPORT
      TM_DIRECTORY
      TM_PROJECT_DIRECTORY
    ].each { |var| path.gsub!('$' + var, ENV[var]) if ENV[var] }
    File.expand_path(path)
  end

  def self.render(output)
    print(output) unless ENV['ENV'] == 'test'
  end

end # module JSLintMate



# Prepare `linter` instance
args   = JSLintMate.args(ARGV)
linter = JSLintMate::Linter.new(
  :key  => args['linter'],
  :path => args['linter-file'],
  :options_from_bundle => args['linter-options'],
  :config_file_path    => args['linter-options-file']
)
filepath = args['file'] || ENV['TM_FILEPATH']
format   = args['format']

# Show results
if format == 'short'
  # Render short string for tooltip
  result = linter.get_short_output(filepath)
  JSLintMate.render(result) if result
else
  # Render HTML for popup
  result = linter.get_html_output(filepath)
  template = ERB.new(JSLintMate.html)
  JSLintMate.render template.result(binding)
end
