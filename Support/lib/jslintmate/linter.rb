require 'yaml'

module JSLintMate

  # Represents a lint tool, JSLint or JSHint.
  class Linter
    # Use `default_options` instead of `DEFAULT_OPTIONS`.
    DEFAULT_OPTIONS = {
      'undef' => false  # `true` if variables and functions need not be
                        # declared before use.
    }
    LINT_REGEXP       = /^(Lint at line )(\d+)(.+?:)(.+?)\n(?:(.+?))?$/
    UNUSED_VAR_REGEXP = /^Unused variable at line (\d+): (.+?)$/

    attr_accessor(
      :key,     # :jslint or :jshint
      :name,    # 'JSLint' or 'JSHint'
      :path,    # Path to the linter JS file
      :options_from_bundle,       # JSON string of bundle options, if any
      :options_from_config_file,  # JSON string of config file options, if any
      :config_file_path           # Path to config file, if any
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
      if attrs[:key] && attrs[:key].to_sym == :jshint
        self.key  = :jshint
        self.name = 'JSHint'
      else
        self.key  = :jslint
        self.name = 'JSLint'
      end

      default_path = JSLintMate.lib_path("#{key}.js")
      self.path    = [attrs[:path], default_path].
                      detect { |path| path && File.readable?(path) }

      self.options_from_bundle      = attrs[:options_from_bundle] || ''
      self.options_from_config_file = ''
      self.config_file_path         = attrs[:config_file_path]

      # Wrap bundle options in braces to better approximate JSON
      if options_from_bundle[0] != '{' && options_from_bundle[-1] != '}'
        self.options_from_bundle = '{' << options_from_bundle << '}'
      end

      # Read options from config file
      if config_file_path
        # Convert path to absolute, e.g., `~/.jslintrc` to
        # `/Users/<username>/.jslintrc`
        self.config_file_path = File.expand_path(config_file_path)

        if File.readable?(config_file_path)
          self.options_from_config_file = YAML.load_file(config_file_path)

          # Store options as a string, never as a hash
          self.options_from_config_file =
            Linter.options_hash_to_string(options_from_config_file)
        else
          # TODO: Show warning if file is unreadable
        end
      end
    end

    def to_s; name; end

    def get_lint_for_filepath(filepath)
      # Returns human-readable errors found in the file at `filepath`. Errors
      # are formatted according to `Support/lib/jsc.js`. Uses OS X's built-in
      # JSC engine.
      #
      # With some hacking, this can probably be made to work with Rhino
      # (Mozilla's open-source JS engine). Reference:
      # <http://www.phpied.com/installing-rhino-on-mac/>

      jsc = JSLintMate.lib_path('jsc.js')
      cmd = '/System/Library/Frameworks/JavaScriptCore.framework/' <<
               %{Versions/A/Resources/jsc "#{self.path}" "#{jsc}" -- } <<
               %{"$(cat "#{filepath}")"}

      cmd << %{ --linter-options-from-defaults="#{
        Linter.default_options.gsub('"', '\\"')
      }"}

      if options_from_bundle && options_from_bundle != ''
        cmd << %{ --linter-options-from-bundle="#{
          options_from_bundle.gsub('"', '\\"')
        }"}
      end

      if options_from_config_file && options_from_config_file != ''
        cmd << %{ --linter-options-from-config-file="#{
          options_from_config_file.gsub('"', '\\"')
        }"}
      end

      `#{cmd}`
    end

    def get_html_output(filepath)
      if filepath
        problems_count = 0

        # Get lint data
        lint = get_lint_for_filepath(filepath)

        # Format errors, if any
        lint.gsub!(Linter::LINT_REGEXP) do
          line, column, desc, code = $2, $3, $4, $5

          # Increment problem counter unless this error is actually an alert,
          # which has no code snippet
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

        if problems_count == 0
          # Douglas Crockford would be so proud.
          output = %{
            <header>
              <span class="desc">Lint-free!</span>
              <span class="filepath">#{filepath}</span>
              #{JSLintMate.link_to_website}
            </header>
            <p class="success">Lint-free!</p>
          }
        else
          output = %{
            <header>
              <span class="desc">Problem#{'s' if
                problems_count > 1} found in:</span>
              <span class="filepath">#{filepath}</span>
              #{JSLintMate.link_to_website}
            </header>
            <ul class="problems">#{lint}</ul>
          }
        end
      else # !filepath
        output = %{
          <header class="alert">
            <span class="desc">Oops!</span>
            #{JSLintMate.link_to_website}
          </header>
          <p class="alert">
            Please save this file before
            #{self} can hurt your feelings.
          </p>
        }
      end

      output.strip!
    end

    def get_short_output(filepath)
      return '' unless filepath

      problems_count = 0
      output = ''

      # Get lint data
      lint = get_lint_for_filepath(filepath)

      # Format errors, if any
      lint.scan(Linter::LINT_REGEXP) do |match|
        line, column, desc, code = $2, $3, $4, $5

        # Increment problem counter unless this error is actually an alert,
        # which has no code snippet
        problems_count += 1 if code
      end

      # Format unused variables, if any
      lint.scan(Linter::UNUSED_VAR_REGEXP) do |match|
        problems_count += 1
      end

      if problems_count == 0
        # For simplicity and less UI noise, display nothing.
        # output = 'Lint-free!'
      else
        output = "#{self} found #{problems_count} problem#{'s' if
                  problems_count > 1}. Run JSLintMate for details."
      end

      output.strip
    end

  end

end
