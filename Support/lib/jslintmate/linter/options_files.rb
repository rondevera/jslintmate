require 'yaml'

module JSLintMate
  class Linter

    # `JSLintMate::Linter` mixin that adds support for reading linter options
    # from a file.
    module OptionsFiles
      DEFAULT_JSLINT_OPTIONS_FILE = '~/.jslintrc'
      DEFAULT_JSHINT_OPTIONS_FILE = '~/.jshintrc'

      def default_options_file(linter_key)
        path =  case linter_key
                when :jslint then DEFAULT_JSLINT_OPTIONS_FILE
                when :jshint then DEFAULT_JSHINT_OPTIONS_FILE
                end
        JSLintMate.expand_path(path)
      end

      def using_custom_options_file?
        self.options_file_paths.any? &&
        self.options_file_paths.first != default_options_file(self.key)
      end

      def first_readable_options_file_path
        @first_readable_options_file_path ||=
          options_file_paths.find { |path| JSLintMate.file_readable?(path) }
      end

      def read_options_from_options_file(linter)
        # Sets `self.options_from_options_file` to a string representation of
        # the options in `self.options_file_paths`.

        return unless self.options_file_paths

        options_file_path = self.first_readable_options_file_path

        if options_file_path
          # Determine order for testing file formats
          formats = (possible_options_file_format(options_file_path) == :json ?
            [:json, :yaml] : [:yaml, :json]
          )
          parsing_strategies = {
            :json => Proc.new { read_options_from_json_file(options_file_path) },
            :yaml => Proc.new { read_options_from_yaml_file(options_file_path) }
          }

          formats.each do |format|
            begin
              break if parsing_strategies[format].call
            rescue ArgumentError => error
              # If an error occurs while looping, ignore it and try the next
              # format, if any.
            end
          end

          if self.options_from_options_file.nil?
            JSLintMate.warn(%{
              The options file "#{options_file_path}" could not be parsed.
            })
          end
        elsif using_custom_options_file?
          # The options file cannot be read, so show a warning. However, not all
          # users will use an options file, so only show the warning if its path
          # has been changed from the default.
          if self.options_file_paths.size == 1
            path = self.options_file_paths.first
            JSLintMate.warn(%{ The options file "#{path}" could not be read. })
          else
            paths = self.options_file_paths.map { |path| '"' << path << '"' }
            JSLintMate.warn(%{
              These options files could not be read: #{paths.join(', ')}
            })
          end
        end
      end

      def possible_options_file_format(options_file_path)
        # Guesses (but does *not* guarantee) the format of `options_file_path`,
        # then returns `:yaml` or `:json`. Assumes that the file is readable.

        # Check file extension
        case File.extname(options_file_path)
        when '.js', '.json'   then return :json
        when '.yml', '.yaml'  then return :yaml
        end

        file_contents = File.read(options_file_path).strip

        # Check first file character
        case file_contents[0, 1]          # Include `,1` for Ruby 1.8.x compat
        when '/', '{' then return :json   # Single-/multi-line comment or object
        when '#'      then return :yaml   # Comment
        end

        # Check last file character
        return :json if file_contents[-1, 1] == '}' # End of an object literal

        # Wild guess
        return :json
      end

      def read_options_from_yaml_file(options_file_path)
        # Sets `self.options_from_options_file` to a string representation of
        # the options in `options_file_path`. Assumes that the file is readable
        # and contains YAML.

        # Verify YAML syntax with `YAML.load_file`
        options_hash = YAML.load_file(options_file_path)

        # Store options as a string, never as a hash
        options_string = Linter.options_hash_to_string(options_hash)
        self.options_from_options_file = options_string
      end

      def read_options_from_json_file(options_file_path)
        # Sets `self.options_from_options_file` to a string representation of
        # the options in `options_file_path`. Assumes that the file is readable
        # and contains JSON or evaluates to a JS object.

        # Convert JS file (containing valid JSON or JS, including comments) to
        # a JSON string
        cmd = %{#{JSC_PATH} -e 'print(JSON.stringify(eval(arguments[0])))' } <<
              %{-- "($(cat "#{options_file_path}"))"}
          # => `./jsc -e 'print(...)' -- "path/to/options.json"`
        options_string = `#{cmd}`
        cmd_status = $?

        if cmd_status.success?
          self.options_from_options_file = options_string
        else
          raise ArgumentError, 'JSON options file could not be parsed'
        end
      end

    end # module OptionsFiles

  end
end
