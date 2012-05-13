require 'yaml'

module JSLintMate
  class Linter

    # Supports reading linter options from a file.
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

      def read_options_from_options_file(linter)
        # Sets `self.options_from_options_file` to a string representation of
        # the options in `self.options_file_path`.

        return unless self.options_file_path

        if JSLintMate.file_readable?(options_file_path)
          # Determine order for testing file formats
          parsing_strategies = {
            :json => Proc.new { read_options_from_json_file },
            :yaml => Proc.new { read_options_from_yaml_file }
          }
          formats = (possible_options_file_format == :json ?
            [:json, :yaml] : [:yaml, :json]
          )

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
              The options file "#{self.options_file_path}" could not be parsed.
            })
          end
        elsif self.options_file_path != default_options_file(linter.key)
          # The options file cannot be read, so show a warning. However, not all
          # users will use an options file, so only show the warning if its path
          # has been changed from the default.
          JSLintMate.warn(%{
            The options file "#{self.options_file_path}" could not be read.
          })
        end
      end

      def possible_options_file_format
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

      def read_options_from_yaml_file
        # Sets `self.options_from_options_file` to a string representation of
        # the options in `self.options_file_path`. Assumes that the file is
        # readable and contains YAML.

        # Verify YAML syntax with `YAML.load_file`
        options_hash = YAML.load_file(options_file_path)

        # Store options as a string, never as a hash
        options_string = Linter.options_hash_to_string(options_hash)
        self.options_from_options_file = options_string
      end

      def read_options_from_json_file
        # Sets `self.options_from_options_file` to a string representation of
        # the options in `self.options_file_path`. Assumes that the file is
        # readable and contains JSON or evaluates to a JS object.

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
