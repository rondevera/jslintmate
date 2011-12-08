require 'cgi'

module JSLintMate

  # Handles JS errors reported by a linter.
  class LintError
    attr_accessor :filepath, :line, :column, :desc, :code

    def initialize(attrs={})
      [:filepath, :line, :column, :desc, :code].each do |attr_name|
        if attrs.has_key?(attr_name)
          self.send("#{attr_name}=", attrs[attr_name])
        end
      end

      # Set required/optional attributes
      self.filepath = attrs[:filepath].to_s
      self.line     = attrs[:line].to_s
      self.column   = (attrs[:column] || 0).to_s  # Optional
      self.desc     = attrs[:desc].to_s
      self.code     = attrs[:code].to_s           # Optional

      # Ensure numeric values for `line` and `column`
      self.line   = self.line.scan(/\d+/)[0].to_s
      self.column = self.column.scan(/\d+/)[0].to_s
    end

    def to_html
      # Returns an HTML representation of this error. If the error has a code
      # snippet, the resulting HTML is an `<a>` that can click through to the
      # actual line in the erroneous file.

      loc_html = %{
        <span class="location">#{CGI.escapeHTML("Line #{line}")}</span>
      }.strip!
        # `loc` omits `column` because `line` is far more commonly used
        # for locating code, and because `column` isn't always available
        # (e.g., for reported unused variables).
      desc_html = %{<span class="desc">#{CGI.escapeHTML(desc).strip}</span>}

      if code == ''
        # Use special formatting for stoppage alerts, e.g., too many errors
        "#{loc_html} #{desc_html}"
      else
        # Use standard formatting for clickable errors
        line_uri = "txmt://open?url=file://#{filepath}" <<
                   "&line=#{CGI.escapeHTML(line)}" <<
                   "&column=#{CGI.escapeHTML(column)}"
        code_html = %{<pre>#{CGI.escapeHTML(code).strip}</pre>}
        %{<a href="#{line_uri}">#{loc_html} #{desc_html} #{code_html}</a>}
      end
    end

  end

end
