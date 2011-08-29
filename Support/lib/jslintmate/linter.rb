module JSLintMate

  # Represents a lint tool, JSLint or JSHint.
  class Linter
    DEFAULT_OPTIONS = {:undef => true}

    attr_accessor :key, :name, :path, :options, :options_filepath



    ### Class methods ###

    def self.options_string_to_hash(options_string)
      # Usage: 'a=1,b=2' # => {'a' => 1, 'b' => 2}
      options_string.split(',').inject({}) do |hsh, kv|
        k, v = kv.split('='); hsh.merge(k => v)
      end
    end

    def self.options_hash_to_string(options_hash)
      # Usage: {:a => 1, 'b' => 2} # => 'a=1,b=2'
      options_hash.map { |k, v| "#{k}=#{v}" }.join(',')
    end

    def self.default_options
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

      self.path = [attrs[:path], JSLintMate.lib_path("#{key}.js")].
                    detect { |path| path && File.readable?(path) }

      [:options, :options_filepath].each do |attr_key|
        self.send(:"#{attr_key}=", attrs[attr_key])
      end

      self.options =
        options ? JSLintMate::Linter.options_string_to_hash(options) : {}
    end

    def to_s; name; end

    def options_string
      JSLintMate::Linter.options_hash_to_string(options)
    end

    def reverse_merge_options_from_file!
      return unless options_filepath && File.readable?(options_filepath)

      require 'yaml'

      # Parse linter options file; file options take precedence over existing
      # options (i.e., default/custom bundle options)
      file_options =
        YAML.load_file(options_filepath).reject{ |k, v| v.is_a?(Array) }
      self.options = options.merge(file_options)
    end

  end

end
