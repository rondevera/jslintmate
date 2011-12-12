JSLintMate
==========

Quick, simple **JSLint (or JSHint) in TextMate**. Hurt your feelings in style.

JSLintMate uses Ruby and [JSC][jsc] behind the scenes; both are part of OS X
by default. No need to install anything else. Everything works offline.

<img src="https://github.com/rondevera/jslintmate/raw/master/Support/images/jslintmate-screenshots.png"
  alt="JSLintMate screenshots" width="892" height="525" />

(CSS geeks: Only three images are used throughout the UI. The red, striped
error uses only CSS.)

*What are these things?* [JSLint][jslint] is a powerful JS code quality tool
from expert Douglas Crockford. [JSHint][jshint] is a community-driven project
based on JSLint, and doesn't hurt your feelings so much. They're not the same
as [JavaScript Lint][javascriptlint], but awesome nonetheless.

[jsc]:            http://trac.webkit.org/wiki/JSC
[jslint]:         http://jslint.com
[jshint]:         http://jshint.com
[javascriptlint]: http://www.javascriptlint.com/


Setup
-----

[Download JSLintMate.tmbundle][download] and double-click it.
TextMate should install it for you automatically&mdash;that's all.

Or via Git:

    # To install for the first time:
    mkdir -p ~/Library/Application\ Support/TextMate/Pristine\ Copy/Bundles
    cd ~/Library/Application\ Support/TextMate/Pristine\ Copy/Bundles
    git clone git://github.com/rondevera/jslintmate.git "JavaScript JSLintMate.tmbundle"
    osascript -e 'tell app "TextMate" to reload bundles'
      # Alternatively, switch to TextMate and select
      # Bundles > Bundle Editor > Reload Bundles.

    # To update to the latest version:
    cd ~/Library/Application\ Support/TextMate/Pristine\ Copy/Bundles
    git pull

[download]: https://github.com/downloads/rondevera/jslintmate/JSLintMate-1.1.tmbundle.zip


Usage
-----

1.  Open a JS file in TextMate.
2.  Hit **control-L** to run it through JSLint (or **control-shift-L** for
    JSHint), and a list of errors appears.
3.  Click an error to jump to that line in the file. Fix and repeat.

### Saving files ###

When you save a JS file with **command-S**, JSLintMate automatically runs it
through JSLint, and reports any problems with a quick little tooltip. If it
finds problems, hit **control-L** to see the full list.

If you'd prefer to run JSHint on save:

1.  Go to *Bundles > Bundle Editor > Show Bundle Editor*.
2.  Expand *JavaScript JSLintMate* and highlight *Linters*.
3.  Change the value for `TM_JSLINTMATE_DEFAULT_LINTER` to `jshint`, then
    close the window.

JSHint should now run whenever you save a JS file. Then, to see JSHint's full
problem list, hit *control-shift-L*.

If you don't want JSLintMate to do anything on save, just open the *Bundle
Editor* window again, and disable the keyboard shortcut for the *Run
JSLintMate and Save* command.


Options
-------

If JSLint or JSHint are too strict or lenient for your taste, you can set
options for each. These options serve as a barebones code style guide, and let
teammates keep their standards synced. Three ways to do this:

* Set options at the **top of each JS file**:

    Adding options atop each JS file gives you fine-grained control. For
    example:

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

    This example is specifically for JSLint. To use it with JSHint, change
    `/*jslint` to `/*jshint` and tweak options as needed.

    The exact option names and values change occasionally. For the latest,
    check the [JSLint docs][jslint options] and the
    [JSHint docs][jshint options].

* Keep a **personal options file**:

    You can use an options file to use your favorite JSLint/JSHint options
    across projects. By default, JSLintMate looks in your home directory for a
    `~/.jslintrc` or `~/.jshintrc` file.

    Your options file(s) should be in YAML format. The simple YAML file used
    by [jslint\_on\_rails][jslint_on_rails config] is a good example, but
    check the latest [JSLint docs][jslint options] and
    [JSHint docs][jshint options] for the exact option names and values.

    If you want to keep your options file somewhere else:

    1.  Within TextMate, select *Bundles > Bundle Editor >
        Show Bundle Editor*.
    2.  Expand *JavaScript JSLintMate* and highlight *Options Files*.
    3.  Change the values for `TM_JSLINTMATE_JSLINT_OPTIONS_FILE` and
        `TM_JSLINTMATE_JSHINT_OPTIONS_FILE` to the file paths you prefer.

* Keep an **options file in your project**:

    You can also store your options file in your project. This is great for
    sharing options with collaborators&mdash;everyone uses the same options
    for all JS files, and different projects can have different options.

    To set this up:

    1.  Within TextMate, select *Bundles > Bundle Editor >
        Show Bundle Editor*.
    2.  Expand *JavaScript JSLintMate* and highlight *Options Files*.
    3.  Change the value for `TM_JSLINTMATE_JSLINT_OPTIONS_FILE` to
        a path in your project, e.g.,
        `$TM_PROJECT_DIRECTORY/config/jslint.yml`. Do the same for JSHint,
        making sure to use a separate options file.

* **Deprecated:** Specify global JSLint/JSHint options for use across
  projects:

    Here's the old way to maintain personal, cross-project options. **This
    feature will be removed in an upcoming version. Please use the "Options
    Files" preferences instead.** Bundle commands no longer need to be
    modified directly.

    1.  Within TextMate, select *Bundles > Bundle Editor > Edit Commands >
        JavaScript JSLintMate > Run JSLintMate*.
    2.  Add your list of options as `--linter-options`. For example:

              ruby "$TM_BUNDLE_SUPPORT/lib/jslintmate.rb" \
                --linter-options=browser:true,onevar:false

If you specify options in your JS files *and* in options files, they'll be
merged at runtime:

1.  Highest precedence: Options in the JS file, e.g.,
    `/*jslint browser: true */`
2.  Options file
3.  JSLintMate's default options

For more info, read about [JSLint's options][jslint options] and
[JSHint's options][jshint options].

[jslint_on_rails config]: https://github.com/psionides/jslint_on_rails/blob/master/lib/jslint/config/jslint.yml
[jslint options]:  http://jslint.com/lint.html#options
[jshint options]:  http://jshint.com/#docs


JSLint/JSHint builds
--------------------

If you're using a custom build of JSLint/JSHint, or want to use and maintain
your own copy of their edge builds, you can modify the JSLintMate bundle
to point to your copy. For example:

    # JSLint:
    ruby path/to/jslintmate.rb \
      --linter-file="$TM_PROJECT_DIRECTORY/lib/jslint.js"

    # JSHint:
    ruby path/to/jslintmate.rb \
      --linter=jshint \
      --linter-file="$TM_PROJECT_DIRECTORY/lib/jslint.js"


About
-----

- **Sharing:** Link to the [official JSLintMate page][website] or use the
  [short URL][shorturl] for this repo!
- **Contributing:** Found a bug or have a suggestion? [Please open an
  issue][issues] or ping [@ronalddevera on Twitter][twitter]. If you want to
  hack on some features, feel free to fork and send a pull request.
  Development happens in the [development branch][dev branch].
- **History:** [History/changelog for JSLintMate][history]
- **Compatibility:** Tested with OS X 10.6+, Safari/WebKit 5+ (6533+), and
  TextMate 1.5.10. Probably works with older software, but it's not
  guaranteed.

This project is adapted from:

- <http://www.phpied.com/jslint-on-mac-textmate/>
- <http://wonko.com/post/pretty-jslint-output-for-textmate>
- <http://blog.pulletsforever.com/2009/07/09/running_jslint_with_safaris_javascript_core/>

JSLintMate is released under the [MIT License][license]. The bundle contains
copies of JSLint and JSHint, which use their own license(s). Use JSLintMate
for good, not evil.

[website]:    http://rondevera.github.com/jslintmate/
[shorturl]:   http://git.io/jslintmate
[issues]:     https://github.com/rondevera/jslintmate/issues
[twitter]:    https://twitter.com/ronalddevera
[dev branch]: https://github.com/rondevera/jslintmate/commits/development
[history]:    https://github.com/rondevera/jslintmate/blob/master/HISTORY
[license]:    https://github.com/rondevera/jslintmate/blob/master/LICENSE
