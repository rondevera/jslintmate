module JSLintMate
  class Linter

    # Supports reading linter options from a file.
    module OptionsFiles

      def read_options_from_config_file
        return unless self.config_file_path

        if File.readable?(config_file_path)
          begin
            read_options_from_yaml_file
          rescue ArgumentError => error
            read_options_from_json_file
          end
        else
          # TODO: Show warning if file is unreadable
        end
      end

      def read_options_from_yaml_file
        # Verify YAML syntax with `YAML.load_file`
        options_string = YAML.load_file(config_file_path)

        # Store options as a string, never as a hash
        options_string = Linter.options_hash_to_string(options_from_config_file)
        self.options_from_config_file = options_string
      end

      def read_options_from_json_file
        # Convert JS file (containing valid JSON or JS) to a JSON string
        cmd = %{#{JSC_PATH} -e 'print(JSON.stringify(eval(arguments[0])))' } <<
              %{-- "($(cat #{config_file_path}))"}
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
