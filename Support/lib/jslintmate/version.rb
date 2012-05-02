module JSLintMate
  def self.version
    @version ||= begin
      version_file_path =
        File.expand_path(File.join(JSLintMate.bundle_path, 'VERSION'))
      File.read(version_file_path).strip
    end
  end

end
