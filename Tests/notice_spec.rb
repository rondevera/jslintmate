require 'spec_helper'

describe JSLintMate::Notice, '#initialize' do
  it 'sets its attributes' do
    type, text = :warn, 'Oh noes'
    notice = JSLintMate::Notice.new(type, text)

    notice.type.should == type
    notice.text.should == text
  end

  it 'validates its attributes' do
    supported_types = JSLintMate::Notice::TYPES
    supported_types.each do |type|
      lambda { JSLintMate::Notice.new(type, 'x') }.should_not raise_error
    end

    lambda { JSLintMate::Notice.new(:foo, 'x') }.
      should raise_error(ArgumentError, /Invalid type/)
    lambda { JSLintMate::Notice.new(nil, 'x') }.
      should raise_error(ArgumentError, /Invalid type/)
    lambda { JSLintMate::Notice.new(supported_types.first, nil) }.
      should raise_error(ArgumentError, /must have text/)
    lambda { JSLintMate::Notice.new(supported_types.first, '') }.
      should raise_error(ArgumentError, /must have text/)
  end
end
