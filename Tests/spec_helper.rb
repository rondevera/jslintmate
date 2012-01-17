ENV['TM_BUNDLE_SUPPORT'] =
  '~/Library/Application Support/TextMate/Pristine Copy/Bundles/' <<
  'JavaScript JSLintMate.tmbundle/Support'
ENV['TM_JSLINTMATE_JSLINT_FILE'] = '$TM_BUNDLE_SUPPORT/lib/jslint.js'
ENV['TM_JSLINTMATE_JSHINT_FILE'] = '$TM_BUNDLE_SUPPORT/lib/jshint.js'
ENV['TM_JSLINTMATE_JSLINT_OPTIONS_FILE'] = '~/.jslintrc'
ENV['TM_JSLINTMATE_JSHINT_OPTIONS_FILE'] = '~/.jshintrc'
ENV['TM_FILEPATH'] = '$TM_BUNDLE_SUPPORT/../Tests/fixtures/test.js'
ENV['ENV'] = 'test'

require 'rspec'
require 'jslintmate'
