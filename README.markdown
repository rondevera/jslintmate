JSLintMate
==========

Quick, simple JSLint (or JSHint) in TextMate. Hurt your feelings in style.

JSLintMate uses jsc and Ruby; both are part of OS X by default. No need to
install anything else.

([JSLint][jslint] is a powerful JS code quality tool from Douglas Crockford.
[JSHint][jshint] is a community-driven project based on JSLint, but doesn't
hurt your feelings so much. They're not the same as
[JavaScript Lint][javascriptlint].)

[jslint]:         http://jslint.com
[jshint]:         http://jshint.com
[javascriptlint]: http://www.javascriptlint.com/


Setup
-----

[Download JSLintMate.tmbundle][download] and double-click it.
TextMate should install it for you automatically.

Or via Git:

    mkdir -p ~/Library/Application\ Support/TextMate/Bundles
    cd ~/Library/Application\ Support/TextMate/Bundles
    git clone git://github.com/rondevera/jslintmate.git "JSLintMate.tmbundle"
    osascript -e 'tell app "TextMate" to reload bundles'
      # If the last command returns an error, switch to TextMate,
      # then select Bundles > Bundle Editor > Reload Bundles.

[download]: https://github.com/rondevera/jslintmate/archives/master


Usage
-----

1.  Open a JS file in TextMate.
2.  Hit **control-L** to run it through JSLint (or **control-shift-L** for
    JSHint), and a list of errors appears.
3.  Click an error to jump to that line in the file. Fix and repeat.


Options
-------

If JSLint is too strict for your taste, you can add JSLint options to the top
of each JS file. These serve as a barebones code style guide, and let a whole
team keep their standards synced. For example:

    /*jslint  browser:  true,
              eqeqeq:   true,
              immed:    false,
              newcap:   true,
              nomen:    false,
              onevar:   true,
              plusplus: false,
              undef:    true,
              white:    false */
    /*global  window, jQuery, $, MyApp */

Tired of listing JSLint options atop every JS file? Here are two alternatives:

* Specify a **YAML config file**:

  1.  Within TextMate, go to Bundles > Bundle Editor > Edit Commands.
  2.  Expand "JSLintMate" and highlight "Run JSLintMate".
  3.  Add the config file path as `--linter-options-file`. For example (no
      line breaks):

            ruby path/to/jslintmate.rb --linter-options-file="$TM_PROJECT_DIRECTORY/config/jslint.yml"

      Customize this file path as needed.

  This is great for sharing a config file with project collaborators, so that
  everyone uses the same JSLint options for all JS files. The YAML config file
  used by [jslint\_on\_rails][jslint_on_rails] is a good example.

* Specify **global JSLint options** for use across projects:

  1.  Within TextMate, go to Bundles > Bundle Editor > Edit Commands.
  2.  Expand "JSLintMate" and highlight "Run JSLintMate".
  3.  Add your list of options as `--linter-options`. For example (no line
      breaks):

            ruby path/to/jslintmate.rb --linter-options=browser=true,onevar=false

  This is useful if you don't have a config file.

Note that you can have different options for JSLint and JSHint by simply
modifying the "Run JSLintMate" and "Run JSLintMate with JSHint" bundles
separately.

For more info, read about [JSLint's options][jslint-options] and
[JSHint's options][jshint-options].

[jslint_on_rails]:  https://github.com/psionides/jslint_on_rails
[jslint-options]:   http://jslint.com/lint.html#options
[jshint-options]:   http://jshint.com/#docs


About
-----

Tested with OS X 10.6 and WebKit 531+ (Safari 4+).

This project is adapted from:

- <http://www.phpied.com/jslint-on-mac-textmate/>
- <http://wonko.com/post/pretty-jslint-output-for-textmate>
- <http://blog.pulletsforever.com/2009/07/09/running_jslint_with_safaris_javascript_core/>
