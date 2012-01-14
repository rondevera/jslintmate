require 'yaml'

module JSLintMate
  class Linter

    # Supports reading linter options from a file.
    module OptionsFiles

      def read_options_from_config_file
        # Sets `self.options_from_config_file` to a string representation of the
        # options in `self.config_file_path`.

        return unless self.config_file_path

        if File.readable?(config_file_path)
          # Determine order for testing file formats
          parsing_strategies = {
            :json => Proc.new { read_options_from_json_file },
            :yaml => Proc.new { read_options_from_yaml_file }
          }
          formats = (possible_config_file_format == :json ?
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

          if self.options_from_config_file.nil?
            # TODO: Show error that the file cannot be parsed. Ignore if
            #       file path is still set to the default.
          end
        else
          # TODO: Show warning that the file cannot be read
        end
      end

      def possible_config_file_format
        # Guesses (but does *not* guarantee) the format of `config_file_path`,
        # then returns `:yaml` or `:json`. Assumes that the file is readable.

        # Check file extension
        case File.extname(config_file_path)
        when '.js', 'json'    then return :json
        when '.yml', '.yaml'  then return :yaml
        end

        file_contents = File.read(config_file_path).strip

        # Check first file character
        case file_contents[0, 1]          # Include `,1` for Ruby 1.8.x compat
        when '/', '{' then return :json   # Single-/multi-line comment or object
        when '#'      then return :yaml   # Comment
        end

        # Check last file character
        return :json if file_contents[-1, 1] == '}'

        # Wild guess
        return :json
      end

      def read_options_from_yaml_file
        # Sets `self.options_from_config_file` to a string representation of the
        # options in `self.config_file_path`. Assumes that the file is readable
        # and contains YAML.

        # Verify YAML syntax with `YAML.load_file`
        options_string = YAML.load_file(config_file_path)

        # Store options as a string, never as a hash
        options_string = Linter.options_hash_to_string(options_from_config_file)
        self.options_from_config_file = options_string
      end

      def read_options_from_json_file
        # Sets `self.options_from_config_file` to a string representation of the
        # options in `self.config_file_path`. Assumes that the file is readable
        # and contains JSON or evaluates to a JS object.

        # Convert JS file (containing valid JSON or JS, including comments) to
        # a JSON string
        cmd = %{#{JSC_PATH} -e 'print(JSON.stringify(eval(arguments[0])))' } <<
              %{-- "($(cat "#{config_file_path}"))"}
          # => `./jsc -e 'print(...)' -- "path/to/options.json"`
        options_string = `#{cmd}`
        cmd_status = $?

        if cmd_status.success?
          self.options_from_config_file = options_string
        else
          raise ArgumentError, 'JSON options file could not be parsed'
        end
      end

    end # module OptionsFiles

  end
end
