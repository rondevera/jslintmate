require 'jslintmate/linter/options_files'

module JSLintMate

  # Represents a lint tool, JSLint or JSHint.
  class Linter
    include OptionsFiles

    # Use `default_options` instead of `DEFAULT_OPTIONS`.
    DEFAULT_OPTIONS = {
      'undef' => false  # `true` if variables and functions need not be
                        # declared before use.
    }
    JSC_PATH          = '/System/Library/Frameworks/' <<
                        'JavaScriptCore.framework/Versions/A/Resources/jsc'
    LINT_REGEXP       = /^(Lint at line )(\d+)(.+?:)(.+?)\n(?:(.+?))?$/
    UNUSED_VAR_REGEXP = /^Unused variable at line (\d+): (.+?)$/

    attr_accessor(
      :key,     # :jslint or :jshint
      :name,    # 'JSLint' or 'JSHint'
      :path,    # Path to the linter JS file
      :options_from_bundle,       # JSON string of bundle options, if any
      :options_from_options_file, # JSON string of options file options, if any
      :options_file_path          # Path to options file, if any
    )

    # N.B.: Linter options are stored as strings, never hashes. Strings are
    #       turned into hashes only via JS. This allows options to be defined
    #       in formats like 'a:1,b:{c:2,d:3}', which JS can parse more easily
    #       than Ruby.



    ### Class methods ###

    def self.options_hash_to_string(options_hash)
      # Returns a valid JSON (string) representation of `options_hash`.
      #
      # Usage:
      #
      #   {:a => 1, 'b' => [2, 3], 'c' => {'d' => 4, 'e' => 5}}
      #     => '{"a":1,"b":[2, 3],"c":{"d":4,"e":5}}'

      options_hash.inspect.gsub!('=>', ':')
    end

    def self.default_options
      # Returns a hash representation of `DEFAULT_OPTIONS`.
      @default_options ||= options_hash_to_string(DEFAULT_OPTIONS)
    end



    ### Instance methods ###

    def initialize(attrs)
      case attrs[:key].to_s
      when 'jslint'
        self.key  = :jslint
        self.name = 'JSLint'
      when 'jshint'
        self.key  = :jshint
        self.name = 'JSHint'
      else
        # User changed the quick mode linter to an invalid key
        JSLintMate.set_error(:text, %{
          Please set your TM_JSLINTMATE_DEFAULT_LINTER preference
          to 'jslint' or 'jshint'.
        })
        return
      end

      self.path = JSLintMate.expand_path(attrs[:path] || default_path)

      # Validate linter path
      unless File.readable?(self.path)
        error_text = %{The linter "#{self.path}" couldn&rsquo;t be read.}

        if self.path == default_path
          # Probably isn't the user's fault, so encourage reporting this bug.
          error_text << ' ' << JSLintMate.link_to_issues
        end

        JSLintMate.set_error(:html, error_text)
        return
      end

      self.options_from_bundle       = attrs[:options_from_bundle] || ''
      self.options_from_options_file = ''
      self.options_file_path         = attrs[:options_file_path]

      # Wrap bundle options in braces to better approximate JSON
      if options_from_bundle[0] != '{' && options_from_bundle[-1] != '}'
        self.options_from_bundle = '{' << options_from_bundle << '}'
      end

      # Read and parse options file
      read_options_from_options_file(self)
    end

    def to_s; name; end

    def default_path
      JSLintMate.lib_path("#{key}.js")
    end

    def build_command_options(opts)
      # Usage:
      #
      #     build_command_options('--a' => 1, '--b' => 2)
      #     => '--a="1" --b="2"'

      opts.inject('') { |str, (k, v)|
        str << %{ #{k}="#{v.gsub('"', '\\"')}"} if v && v != ''
        str
      }.strip!
    end

    def get_lint_for_filepath(filepath)
      # Returns human-readable errors found in the file at `filepath`. Errors
      # are formatted according to `Support/lib/jsc.js`. Uses OS X's built-in
      # JSC engine.
      #
      # With some hacking, this can probably be made to work with Rhino
      # (Mozilla's open-source JS engine). Reference:
      # <http://www.phpied.com/installing-rhino-on-mac/>

      # Stop if an error has already occurred, e.g., the linter file couldn't
      # be read
      return if JSLintMate.error?

      jsc_adapter_path = JSLintMate.lib_path('jsc.js')

      unless File.executable?(JSC_PATH)
        JSLintMate.set_error(:html, %{
          Ack, sorry. JSC isn&rsquo;t running properly on this computer.
          #{JSLintMate.link_to_issues}
        })
        return
      end

      unless File.readable?(jsc_adapter_path)
        JSLintMate.set_error(:html, %{
          Argh, sorry. The linter output couldn&rsquo;t be formatted properly.
          #{JSLintMate.link_to_issues}
        })
        return
      end

      cmd = %{#{JSC_PATH} "#{self.path}" "#{jsc_adapter_path}" -- } <<
              %{"$(cat "#{filepath}")"} << ' ' <<
              build_command_options(
                '--linter-options-from-defaults'     => Linter.default_options,
                '--linter-options-from-bundle'       => options_from_bundle,
                '--linter-options-from-options-file' => options_from_options_file
              )

      `#{cmd}`
    end

    def get_html_output(filepath)
      results_template = ERB.new(File.read(
        JSLintMate.views_path('results.html.erb')))
      template_locals = {}

      if filepath
        problems_count = 0
        lint = get_lint_for_filepath(filepath)
        template_locals[:filepath] = filepath

        if lint
          # Format errors, if any
          lint.gsub!(Linter::LINT_REGEXP) do
            line, column, desc, code = $2, $3, $4, $5

            # Increment problem counter unless this error is actually a linter
            # alert, which has no code snippet
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
          lint.gsub!(Linter::UNUSED_VAR_REGEXP) do
            line, code = $1, $2

            problems_count += 1

            JSLintMate.error_to_html(
              :filepath => filepath,
              :line     => line,
              :code     => code,
              :desc     => 'Unused variable.'
            )
          end

          template_locals[:notices] = JSLintMate.notices
          if problems_count == 0
            template_locals.merge!(
              :desc     => 'Lint-free!', # Douglas Crockford would be so proud.
              :results  => %{<p class="success">Lint-free!</p>}
            )
          else
            template_locals.merge!(
              :desc     => "Problem#{'s' if problems_count > 1} found in:",
              :results  => %{<ul class="problems">#{lint}</ul>}
            )
          end
        end

      else # No filepath
        JSLintMate.set_error(:html, %{
          Please save this file before #{self} can hurt your feelings.
        })
      end

      if JSLintMate.error_for(:html)
        template_locals.merge!(
          :desc    => 'Oops!',
          :notices => JSLintMate.notices,
          :results => %{
            <p class="error">
              <span class="text">#{JSLintMate.error_for(:html)}</span>
            </p>
          }
        )
      end

      results_template.result(binding).strip!
    end

    def get_short_output(filepath)
      return '' unless filepath

      # If an error occurred pertaining to quick mode, return/abort
      error = JSLintMate.error_for(:text)
      return error if error

      problems_count = 0
      lint_preview = []
      lint_preview_max = 3
      output = ''
      lint = get_lint_for_filepath(filepath)

      if lint
        # Format errors, if any
        lint.scan(Linter::LINT_REGEXP) do |match|
          line, column, desc, code = $2, $3, $4, $5

          # Increment problem counter unless this error is actually a linter
          # alert, which has no code snippet
          problems_count += 1 if code

          if problems_count <= lint_preview_max
            lint_preview << {:filepath => filepath, :line => line, :desc => desc}
          end
        end

        # Format unused variables, if any
        lint.scan(Linter::UNUSED_VAR_REGEXP) do |match|
          problems_count += 1
        end
      end

      if problems_count == 0
        # For simplicity and less UI noise, display nothing.
        # output = 'Lint-free!'
      else
        # Format lint preview strings
        max_line_number_width =
          lint_preview.map { |lint| lint[:line] }.max.to_s.size
        lint_preview = lint_preview.map do |lint|
          JSLintMate.error_to_text(
            :line       => lint[:line],
            :line_width => max_line_number_width,
            :desc       => lint[:desc]
          )
        end.join("\n")

        # Build output string
        output =  "#{self} found #{problems_count} " <<
                  "problem#{'s' if problems_count > 1}. " <<
                  "Run JSLintMate for details."
        output << "\n\nPreview:\n" << lint_preview if lint_preview != ''
      end

      output.strip
    end

  end

end
