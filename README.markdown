JSLintMate
==========

Quick, simple **JSLint and JSHint in TextMate**. Hurt your feelings in style.

JSLintMate uses [Ruby][ruby] and [JSC][jsc] behind the scenes; both are part
of OS X by default. No need to install anything else. Everything works
offline.

[Download JSLintMate.tmbundle][download]

<img src="http://rondevera.github.com/jslintmate/img/jslintmate-screenshots.png"
  alt="JSLintMate screenshots" width="850" height="541" />

(CSS geeks: Only three images are used throughout the UI. The red, striped
error uses only CSS.)

*What are these things?* [JSLint][jslint] is a powerful JS code quality tool
from expert Douglas Crockford. [JSHint][jshint] is a community-driven project
based on JSLint, and is more tolerant of common JS patterns. (They're not the
same as [JavaScript Lint][javascriptlint].)

[ruby]:           http://www.ruby-lang.org/
[jsc]:            http://trac.webkit.org/wiki/JSC
[jslint]:         http://jslint.com
[jshint]:         http://jshint.com
[javascriptlint]: http://www.javascriptlint.com/


Key features
------------

* Quick JSLint/JSHint on **command-S**.
* Full problem details on **control-L** (JSLint) or **control-shift-L**
  (JSHint)&mdash;both customizable. Navigate the list with full
  mouse/trackpad/keyboard support.
* Support for **options files** that help you&mdash;and your teammates&mdash;use
  the same coding standards everywhere. Options files can live in your home
  directory or in project repositories. They use standard JSON/YAML, so they can
  be read not just by JSLintMate, but also by teammates' lint tools in other
  editors, automated testing systems, continuous integration systems, and more.
* Support for using your own **custom or edge build** of JSLint or JSHint.


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

### TextMate 2 ###

**Installation:** If your computer has only TextMate 2, just
[download JSLintMate.tmbundle][download] and double-click to install it.

If your computer has both TextMate 1.x and 2.x, installation is
[temporarily a bit more involved][textmate 2 bundles] while TextMate 2 is in
development:

1.  [Download JSLintMate.tmbundle][download] and unzip it.
2.  Create the bundles path: `mkdir -p ~/Library/Application\ Support/Avian/Pristine\ Copy/Bundles/`.
2.  Open the same path: `open ~/Library/Application\ Support/Avian/Pristine\ Copy/Bundles/`.
3.  Drop `JavaScript JSLintMate.tmbundle` into the `Bundles` directory.

**Project setup:** It's worth creating a `.tm_properties` file in your project
directory containing this ([source][tm_properties]):

    projectDirectory     = "$CWD"
    TM_PROJECT_DIRECTORY = "$projectDirectory"

This lets you use `$TM_PROJECT_DIRECTORY` in your JSLintMate settings, which is
useful for pointing to project-specific JSLint/JSHint options and custom builds.

**Display:** In TextMate 2, JSLintMate runs in a panel in the main window,
rather than in a separate window. If you want TextMate 2 to open JSLintMate in a
separate window, run this in Terminal
([source][textmate 2 htmlOutputPlacement]):

    defaults write com.macromates.TextMate.preview htmlOutputPlacement window


[download]: https://github.com/downloads/rondevera/jslintmate/JavaScript%20JSLintMate%201.4.tmbundle.zip
[textmate 2 bundles]: http://blog.macromates.com/2011/locating-bundles/
[textmate 2 htmlOutputPlacement]: http://lists.macromates.com/textmate/2011-December/033616.html
[tm_properties]:   https://gist.github.com/1478685


Usage
-----

JSLintMate has two modes:

* **Quick mode** shows a tooltip with a preview of the problems (if any)
  whenever you hit **command-S**.

* **Full mode** shows a full list of problems whenever you hit **control-L**
  (JSLint) or **control-shift-L** (JSHint).


### Quick mode ###

While you're coding, hit **command-S** to save changes and automatically run the
file through JSLint. If any problems are found, JSLintMate shows a few of them
in a tooltip.

If you'd prefer to run JSHint on save:

1.  Select *Bundles > Bundle Editor > Show Bundle Editor*.
2.  Expand *JavaScript JSLintMate* and highlight *Linters*.
3.  Change the value for `TM_JSLINTMATE_DEFAULT_LINTER` to `jshint`, then
    close the window to save changes.

If you don't want JSLintMate to do anything on save, open the *Bundle Editor*
window again, and remove the keyboard shortcut for the *Run JSLintMate and
Save* command.

To skip the tooltip and see the full list of problems, use **full mode**.


### Full mode ###

To see the full list of problems in a JS file, hit **control-L** to run it
through JSLint, or **control-shift-L** to use JSHint. Click a problem to jump
to that line in the file. Fix and repeat.

You can also navigate the list of problems with your keyboard: *up/down/k/j*
to move up/down, and *return* to select.


Options
-------

If JSLint or JSHint are too strict or lenient for your taste, you can set
options for each. These options serve as a barebones code style guide, and let
teammates stick to the same standards. Three ways to do this:

### Set options at the top of each JS file ###

Adding options atop each JS file gives you fine-grained control. For
example:

      /*jslint  browser:  true,
                newcap:   true,
                nomen:    false,
                plusplus: false,
                undef:    false,
                vars:     false,
                white:    false */
      /*global  window, jQuery, $, MyApp */

This example is specifically for JSLint. To use it with JSHint, change
`/*jslint` to `/*jshint` and tweak options as needed.

The exact option names and values change occasionally. For the latest,
check the [JSLint docs][jslint options] and the
[JSHint docs][jshint options].

### Keep a personal options file ###

You can maintain an options file to use your favorite JSLint/JSHint options
across projects. These files can be written in JSON or YAML.

To get you started, JSLintMate comes with some example options files:
[jslint.json][jslint.json], [jslint.yml][jslint.yml],
[jshint.json][jshint.json], and [jshint.yml][jshint.yml]. To use one of
these, save a copy as `~/.jslintrc` or `~/.jshintrc`. JSLintMate reads from
these paths by default, and automatically detects whether they contain JSON
or YAML.

If you want to rename your options files or store them elsewhere:

1.  Within TextMate, select *Bundles > Bundle Editor >
    Show Bundle Editor*.
2.  Expand *JavaScript JSLintMate* and highlight *Options Files*.
3.  Change the values for `TM_JSLINTMATE_JSLINT_OPTIONS_FILE` and
    `TM_JSLINTMATE_JSHINT_OPTIONS_FILE` to the file paths you prefer.

### Keep an options file in your project ###

You can also store your options file in your project. This is great for
sharing options with collaborators&mdash;everyone uses the same options
for all JS files, and different projects can have different options.

To set this up:

1.  Within TextMate, select *Bundles > Bundle Editor >
    Show Bundle Editor*.
2.  Expand *JavaScript JSLintMate* and highlight *Options Files*.
3.  Change the value for `TM_JSLINTMATE_JSLINT_OPTIONS_FILE` to
    a path in your project, e.g.,
    `$TM_PROJECT_DIRECTORY/config/jslint.yml`. Do the same for JSHint if
    needed, making sure to use a separate options file.

To get you started, JSLintMate comes with some example options files:
[jslint.json][jslint.json], [jslint.yml][jslint.yml],
[jshint.json][jshint.json], and [jshint.yml][jshint.yml]. To use one of these,
save a copy in your project at the path you chose above.

Options files are meant to be understood by a wide variety of tools, not
just JSLintMate. This includes lint tools in other editors, continuous
integration systems, and other automated testing systems.

### Deprecated: Specify global options for use across projects ###

Here's the old way to maintain personal, cross-project options. **This
feature will be removed in an upcoming version. Please use a
`~/.jslintrc` or `~/.jshintrc` file via the "Options Files" preferences
instead.** Bundle commands no longer need to be modified directly.

1.  Within TextMate, select *Bundles > Bundle Editor > Edit Commands >
    JavaScript JSLintMate > Run JSLintMate*.
2.  Add your list of options as `--linter-options`. For example:

          ruby "$TM_BUNDLE_SUPPORT/lib/jslintmate.rb" \
            --linter-options=browser:true,white:false

---

### Options file fallbacks ###

`TM_JSLINTMATE_JSLINT_OPTIONS_FILE` and `TM_JSLINTMATE_JSHINT_OPTIONS_FILE`
support options file fallbacks. Change each setting to a colon-separated list of
file paths, and JSLintMate will use the first readable file in each list.

For example, `$TM_PROJECT_DIRECTORY/config/jslint.json:~/.jslintrc` tells
JSLintMate to first look for a project-specific options file (e.g., for options
shared with a team). If this file is not readable, JSLintMate uses your personal
options file as a fallback.

### Option precedence ###

If you specify options in your JS files *and* in options files, they'll be
merged at runtime:

1.  Highest precedence: Options in the JS file, e.g.,
    `/*jslint browser: true */`
2.  First readable options file
3.  JSLintMate's default options

For more info, read about [JSLint's options][jslint options] and
[JSHint's options][jshint options].

[jslint.json]:     https://raw.github.com/rondevera/jslintmate/master/Support/config/jslint.json
[jslint.yml]:      https://raw.github.com/rondevera/jslintmate/master/Support/config/jslint.yml
[jshint.json]:     https://raw.github.com/rondevera/jslintmate/master/Support/config/jshint.json
[jshint.yml]:      https://raw.github.com/rondevera/jslintmate/master/Support/config/jshint.yml
[jslint options]:  http://jslint.com/lint.html#options
[jshint options]:  http://www.jshint.com/options/


Unused variables
----------------

JSLintMate reports warnings from JSLint/JSHint about variables that are declared
but not used. It's good to clean up code by removing unused variables, but if
you'd rather not see these warnings:

1.  Within TextMate, select *Bundles > Bundle Editor > Show Bundle Editor*.
2.  Expand *JavaScript JSLintMate* and highlight *Unused Variables*.
3.  Change the value of `TM_JSLINTMATE_WARN_ABOUT_UNUSED_VARIABLES` to `false`.

To resume seeing warnings about unused variables, set this value back to `true`.


Custom JSLint/JSHint builds
---------------------------

JSLintMate is packaged with copies of JSLint and JSHint, but you can use your
own copies instead. This is useful for testing an edge build or using your
own modified version.

If you store a copy of your linter in your project, point your bundle prefs at
it:

1.  Within TextMate, select *Bundles > Bundle Editor > Show Bundle Editor*.
2.  Expand *JavaScript JSLintMate* and highlight *Linters*.
3.  Change the value for `TM_JSLINTMATE_JSLINT_FILE` to point to your linter.
    This could be a path in your project (e.g.,
    `$TM_PROJECT_DIRECTORY/lib/jslint.js`), a path in your home directory
    (e.g., `~/lib/jslint.js`), or anything else. If needed, do the same for
    JSHint, making sure to use a separate linter file.


About
-----

- **Sharing:** Link to the [official JSLintMate page][website] or use the
  [short URL][shorturl] for this repo!
- **Contributing:** Found a bug or have a suggestion? [Please open an
  issue][issues] or ping [@ronalddevera on Twitter][twitter]. If you want to
  hack on some features, feel free to fork and send a pull request for the
  **[development branch][dev branch]**. (The master branch is for stable builds
  only.)
- **History:** [History/changelog for JSLintMate][history]
- **Compatibility:** Tested with OS X 10.6+, Safari/WebKit 5+ (6533+), and
  TextMate 1.5.10+ (including TextMate 2.0a). Probably works with older
  software, but it's not guaranteed.

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
