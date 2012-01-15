module JSLintMate

  # Supports rendering notices (not lint problems) in the output view.
  class Notice
    TYPES = [:debug, :warn, :error]

    attr_accessor :type, :text

    def initialize(type, text)
      unless TYPES.include?(type)
        raise ArgumentError, "Invalid type: #{type}" and return
      end

      if !text || text == ''
        raise ArgumentError, 'A Notice must have text.' and return
      end

      self.type = type
      self.text = text
    end

  end
end
