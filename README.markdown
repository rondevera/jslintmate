JSLintMate
==========

Quick, simple JSLint (or JSHint) in TextMate. Hurt your feelings in style.

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
2.  Hit **ctrl-L** to run it through JSLint (or **ctrl-shift-L** for JSHint),
    and a list of errors appears.
3.  Click an error to jump to that line in the file. Fix and repeat.


Options
-------

If JSLint is too strict for your taste, add JSLint options to the top of
each JS file. These serve as a barebones code style guide, and let a whole
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

Tired of putting JSLint flags atop every JS file? You can specify global
options:

1.  Within TextMate, go to Bundles > Bundle Editor > Edit Commands.
2.  Expand "JSLintMate" and highlight "Run JSLintMate".
3.  Right after the whole `ruby path/to/jslintmate.rb` command, add
    ` --linter-options=browser=true,onevar=false` (no line breaks), or any
    options you want. You can have different options for JSLint and JSHint.

For more info, read about [JSLint's options][jslint-options] and
[JSHint's options][jshint-options].

[jslint-options]: http://jslint.com/lint.html#options
[jshint-options]: http://jshint.com/#docs


About
-----

Tested with OS X 10.6 and WebKit 531+ (Safari 4+).

This project is adapted from:

- <http://www.phpied.com/jslint-on-mac-textmate/>
- <http://www.phpied.com/installing-rhino-on-mac/>
- <http://wonko.com/post/pretty-jslint-output-for-textmate>
- <http://www.pulletsforever.com/pulletsforever/Pullets_Forever_Blog/Entries/2009/7/12_Running_JSLint_with_Safaris_JavaScript_Core.html>
