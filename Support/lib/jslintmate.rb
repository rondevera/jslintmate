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
#   --file            '/path/to/my-file.js'; defaults to
#                     `ENV['TM_FILEPATH']`
#   --linter          'jslint' (default) or 'jshint'
#   --linter-file     [deprecated] '/path/to/jslint.js' or
#                     '/path/to/jshint.js'
#   --linter-options  [deprecated] Format: 'option1:value1,option2:value'
#
# Options precedence:
#
#   1.  Highest precedence: In-file options, e.g.,
#       `/*jslint browser: true, ... */`
#   2.  Options file (via `TM_JSLINTMATE_JSLINT_OPTIONS_FILE` or
#       `TM_JSLINTMATE_JSHINT_OPTIONS_FILE`)
#   3.  [deprecated] Custom bundle preferences (via `--linter-options`)
#   4.  Default bundle preferences (via `JSLintMate::Linter#default_options`)
#
# To update jslint.js and jshint.js:
#
#   cd /path/to/JavaScript JSLintMate.tmbundle/Support/lib/
#   curl -o jslint.js http://jslint.com/jslint.js
#   curl -o jshint.js http://jshint.com/jshint.js

$LOAD_PATH << File.expand_path(
  File.join(ENV['TM_BUNDLE_SUPPORT'] || 'Support', 'lib'))

require 'erb'
Dir.glob(File.dirname(__FILE__) << '/jslintmate/*.rb').each do |file|
  require file
end

module JSLintMate
  ISSUES_URL  = 'https://github.com/rondevera/jslintmate/issues'
  README_URL  = 'https://github.com/rondevera/jslintmate/#readme'
  WEBSITE_URL = 'http://rondevera.github.com/jslintmate/'

  def self.args(args_string)
    # Returns a hash of arguments based on `args_string`, the bundle's
    # preferences, and the bundle's defaults.

    args = args_to_hash(args_string)

    # Add deprecation warnings
    deprecate_arg(args, 'file')
    deprecate_arg(args, 'linter-file',    'Linters')
    deprecate_arg(args, 'linter-options', 'Options Files')

    # Merge with defaults
    args['file']   ||= ENV['TM_FILEPATH']
    args['linter'] ||= 'jslint'
    use_jshint     = args['linter'] == 'jshint'
    args['linter-file'] ||= use_jshint ?
      (ENV['TM_JSLINTMATE_JSHINT_FILE'] || '').dup :
      (ENV['TM_JSLINTMATE_JSLINT_FILE'] || '').dup
    args['linter-options-files'] = use_jshint ?
      (ENV['TM_JSLINTMATE_JSHINT_OPTIONS_FILE'] || '').dup :
      (ENV['TM_JSLINTMATE_JSLINT_OPTIONS_FILE'] || '').dup

    # Expand file paths
    args['file'] = JSLintMate.expand_path(args['file'])
    args['linter-file'] = JSLintMate.expand_path(args['linter-file'])
    args['linter-options-files'] = args['linter-options-files'].
      split(':').map { |path| JSLintMate.expand_path(path) }

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

  def self.deprecate_arg(args, deprecated_arg_name, prefs_name=nil)
    if args[deprecated_arg_name]
      warning = %{
        The <code>--#{deprecated_arg_name}</code> option is deprecated, and will
        be removed in a future version.
      }.strip!
      if prefs_name
        warning << ' ' << %{
          Instead, open TextMate&rsquo;s bundle editor (in the
          &ldquo;Bundles&rdquo; menu) and use JSLintMate&rsquo;s
          &ldquo;#{prefs_name}&rdquo; settings.
          (<a href="#{README_URL}">More info</a>)
        }.strip!
      end
      JSLintMate.warn(warning)
    end
  end

  def self.lib_path(*args)
    # Usage:
    #
    #   lib_path          # => /path/to/JavaScript JSLintMate.tmbundle/Support/lib
    #   lib_path('x.js')  # => /path/to/JavaScript JSLintMate.tmbundle/Support/lib/x.js

    dirs = ['lib'] << args
    File.expand_path(File.join(bundle_path, 'Support', *dirs))
  end

  def self.views_path(*args)
    # Usage:
    #
    #   views_path           # => /path/to/JavaScript JSLintMate.tmbundle/Support/lib/jslintmate/views
    #   views_path('x.css')  # => /path/to/JavaScript JSLintMate.tmbundle/Support/lib/jslintmate/views/x.css

    dirs = %w[lib jslintmate views] << args
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

  def self.file_readable?(path)
    File.file?(path) && File.readable?(path)
  end

  def self.html ; File.read views_path('main.html.erb') ; end
  def self.css  ; File.read views_path('main.css')      ; end
  def self.js
    File.read(views_path('main.js')) <<
    File.read(views_path('version.js'))
  end

  def self.link_to_website(options = {})
    title = "About JSLintMate #{version}"

    if options[:options_file_path]
      title << "\n\nOptions file: #{options[:options_file_path]}"
    end

    title.gsub!('"', '&quot;')
    %{<a href="#{WEBSITE_URL}" class="info" title="#{title}">info</a>}
  end

  def self.link_to_issues(text='Report this')
    %{<a href="#{ISSUES_URL}" class="issues">#{text}</a>}
  end

  def self.error_to_text(error_data, options={})
    # `error_data` is a hash whose keys should match
    # `JSLintMate::LintError#initialize`.
    #
    # Returns a plain text string that represents the given error data.
    #
    # Options:
    # - `:line_width`:  The width of the "Line #" half of the string. Useful
    #                   for producing text in neat columns.

    line_width = error_data.delete(:line_width)
    to_s_options = (line_width.nil? ? {} : {:line_width => line_width})

    JSLintMate::LintError.new(error_data).to_s(to_s_options)
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

    return '' if path.nil? || path == ''

    path = path.dup
    %w[
      TM_BUNDLE_SUPPORT
      TM_DIRECTORY
      TM_PROJECT_DIRECTORY
    ].each { |var| path.gsub!('$' + var, ENV[var]) if ENV[var] }
    File.expand_path(path)
  end

  def self.notices ; @notices ||= [] ; end

  def self.add_notice(type, text)
    @notices ||= []
    notice = Notice.new(type, text.strip)
    @notices << notice unless @notices.map(&:text).include?(notice.text)
  end

  def self.clear_notices ; @notices = [] ; end

  def self.debug(obj)
    text = obj.respond_to?(:strip) ? obj.strip : obj.inspect
    add_notice(:debug, text)
  end

  def self.warn(text)
    add_notice(:warn, text)
  end

  def self.error?
    # Returns a truthy value if an error exists for any format.
    @error_text && !@error_text.empty?
  end

  def self.error_for(format)
    # Returns a string if an error exists for the given format, nil otherwise.

    unless [:html, :text].include?(format)
      raise ArgumentError,
        'Errors can only be presented in :html or :text formats.' and return
    end

    @error_text if @error_format == format.to_sym
  end

  def self.set_error_for(format, text)
    unless [:html, :text].include?(format)
      raise ArgumentError,
        'Errors can only be presented in :html or :text formats.' and return
    end

    @error_format = format
    @error_text   = text.strip.gsub(/\s+/, ' ')
  end

  def self.clear_errors
    @error_format = @error_text = nil
  end

  def self.render(output)
    print(output) unless ENV['ENV'] == 'test'
  end

  def self.start!
    # Prepare `linter` instance
    args   = JSLintMate.args(ARGV)
    linter = JSLintMate::Linter.new(
      args['linter'],
      :path => args['linter-file'],
      :options_from_bundle => args['linter-options'],
      :options_file_paths  => args['linter-options-files']
    )
    filepath = JSLintMate.expand_path(args['file'])
    format   = args['format']

    # Show results
    if format == 'short'
      # Render short string for tooltip
      result = linter.get_short_output(filepath)
      JSLintMate.render(result) if result
    else
      # Render HTML for popup/panel
      result = linter.get_html_output(filepath)
      template = ERB.new(JSLintMate.html)
      JSLintMate.render template.result(binding)
    end
  end

end # module JSLintMate

JSLintMate.start!
