require 'spec_helper'

describe JSLintMate do
  it 'returns its version' do
    version = '1.x.x'
    version_file_path =
      File.expand_path(File.join(JSLintMate.bundle_path, 'VERSION'))
    File.should_receive(:read).with(version_file_path).once { version }

    JSLintMate.instance_variable_set(:@version, nil) # Clear memoized value
    JSLintMate.version.should == version
    JSLintMate.version # Tests for memoization
  end

end
