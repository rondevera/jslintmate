JSLintMate
==========

Quick, simple JSLint in TextMate. Hurt your feelings in style.
([JSLint][jslint] is a powerful JS code quality tool. It's not the same as
[JavaScript Lint][javascriptlint].)

[jslint]:         http://jslint.com
[javascriptlint]: http://www.javascriptlint.com/


Setup
-----

Via Git:

    mkdir -p ~/Library/Application\ Support/TextMate/Bundles
    cd ~/Library/Application\ Support/TextMate/Bundles
    git clone git://github.com/rondevera/jslintmate.git "JSLintMate.tmbundle"
    osascript -e 'tell app "TextMate" to reload bundles'
      # If the last line shows an error, switch to TextMate,
      # then select Bundles > Bundle Editor > Reload Bundles.


Usage
-----

Open a JS file in TextMate. Hit ctrl-L, and a list of errors appears. Click
each error to jump to that line in the file. Fix and repeat.

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

The JSLint website has [more info on supported options][jslint-options].

[jslint-options]: http://jslint.com/#JSLINT_OPTIONS


About
-----

Tested with OS X 10.6 and WebKit 531+ (Safari 4+).

This project is adapted from:

- <http://www.phpied.com/jslint-on-mac-textmate/>
- <http://www.phpied.com/installing-rhino-on-mac/>
- <http://wonko.com/post/pretty-jslint-output-for-textmate>
- <http://www.pulletsforever.com/pulletsforever/Pullets_Forever_Blog/Entries/2009/7/12_Running_JSLint_with_Safaris_JavaScript_Core.html>
