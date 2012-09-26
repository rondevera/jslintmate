require 'spec_helper'

describe JSLintMate::Notice do
  describe '#initialize' do
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

  describe '#to_s' do
    it 'returns text' do
      notice = JSLintMate::Notice.new(:warn, 'asdf')
      notice.to_s.should == 'asdf'
    end
  end

  describe '#to_html' do
    it 'returns text as valid HTML' do
      notice = JSLintMate::Notice.new(:warn, 'asdf')
      notice.to_html.should == 'asdf'

      notice.text = '<p>foo & "bar"</p>'
      notice.to_html.should == '&lt;p&gt;foo &amp; &quot;bar&quot;&lt;/p&gt;'
    end
  end

end
