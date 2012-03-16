// Processes a JS file with a lint tool, then prints human-readable
// descriptions of each error. Run this after `jslint.js` or `jshint.js` so
// that JSC can run it.
//
// More on JSC: https://trac.webkit.org/wiki/JSC
//
// Adapted from:
// - http://blog.pulletsforever.com/2009/07/09/running_jslint_with_safaris_javascript_core/
// - https://github.com/jshint/jshint/blob/master/env/rhino.js
//
// Copyright (c) 2002 Douglas Crockford (www.JSLint.com) JSC Edition
// Copyright (c) 2009 Apple Inc.

/*jslint  browser:  false,
          evil:     true,
          newcap:   true,
          nomen:    true,
          plusplus: true,
          rhino:    true,
          sloppy:   true,
          vars:     false,
          white:    true */
/*jshint  plusplus: false,
          white:    false */
/*global  JSLINT, JSHINT */



(function(args) {
  var Runner    = {},
      filename  = args[0],
      linter    = (typeof JSHINT !== 'undefined' ? JSHINT : JSLINT),
      options   = args.slice(1), // Array; all but first
      linterOptions = {},
      linterData;



  /*** Options ***/

  Runner.Options = {};

  Runner.Options.stringToHash = function (string) {
    // Given a string '{a:1,b:[2,3],c:{d:4,e:5}}`, returns an object/hash.

    try {
      return string ? eval('(' + string + ')') : {};
        // Using `eval` because the input might not be valid JSON. Trusts that
        // any collaborators aren't messing with each other.
    } catch (e) {
      return {}; // Not parseable
    }
  };

  Runner.Options.parse = function (optionsArray) {
    // Given an array `optionsArray`, returns a hash where each array item
    // is split into a key and value. Known linter options are also converted
    // into hashes.

    var options = {},
        i, option, key, value;

    i = optionsArray.length; while (i--) {
      // Split option (e.g., 'a=b=c') into key and value (e.g., 'a' and 'b=c')
      option = optionsArray[i];         // option = 'a=b=c'
      key    = option.split('=');       // key    = ['a', 'b', 'c']
      value  = key.slice(1).join('=');  // value  = 'b=c'
      key    = key[0];                  // key    = 'a'

      // Convert known linter options to hashes
      switch (key) {
        case '--linter-options-from-bundle':
        case '--linter-options-from-options-file':
        case '--linter-options-from-defaults':
          value = Runner.Options.stringToHash(value); break;
      }

      // Copy to hash
      options[key] = value;
    }

    return options;
  };

  Runner.Options.build = function (options) {
    // Given a hash of options from `Runner.Options.parse`, returns a merged
    // hash of options to be used by the linter.

    var linterOptions = {};

                                                      // Precedence:
    Runner.Util.merge(linterOptions,
      options['--linter-options-from-defaults']);     // <- lowest
    Runner.Util.merge(linterOptions,
      options['--linter-options-from-bundle']);
    Runner.Util.merge(linterOptions,
      options['--linter-options-from-options-file']); // <- highest
      // The linter options in the target file override these
      // (i.e., have top precedence).

    return linterOptions;
  };

  Runner.Options.shouldWarnAboutUnusedVars = function () {
    return options['--warn-about-unused-vars'] === 'true';
  };



  /*** Lint ***/

  Runner.Lint = {};

  Runner.Lint.find = function (linter, linterOptions, filename) {
    var linterData;

    linter(filename, linterOptions);
    linterData = linter.data();

    if (!linterData.unused) {
      // The key (`unused` or `unuseds`) varies across JSHint and various
      // versions of JSLint. Normalize as `unused`.
      linterData.unused = linterData.unuseds; // Value may be `null`
    }

    if (!Runner.Options.shouldWarnAboutUnusedVars()) {
      delete linterData.unused;
    }

    return linterData;
  };



  /*** Utilities ***/

  Runner.Util = {};

  Runner.Util.merge = function (orig, overrides) {
    // Overwrites properties in `orig` (hash) with properties from `overrides`
    // in place. Shallow only.

    var key;

    if (!overrides) { return; }
    for (key in overrides) {
      if (typeof overrides[key] !== 'undefined' &&
          overrides.hasOwnProperty(key)) {
        orig[key] = overrides[key];
      }
    }
  };



  // Check for JS code
  if (!filename) {
    print('Usage: jsc (jslint|jshint).js jsc.js -- "$(cat myFile.js)"' +
          ' [--linter-options-from-bundle=\'a:1,b:[2,3]\']' +
          ' [--linter-options-from-options-file=\'c:4,d:{e:5,f:6}\']' +
          ' [--linter-options-from-defaults=\'g:7\']' +
          ' [--warn-about-unused-vars=true|false]'
    );
    quit(1);
  }

  // Run linter and fetch data
  options       = Runner.Options.parse(options);
  linterOptions = Runner.Options.build(options);
  linterData    = Runner.Lint.find(linter, linterOptions, filename);

  if (linterData.errors || linterData.unused) {
    // Format errors
    (function() {
      // TODO: Move to a separate named function

      var errors = (linter.errors || []).concat(linterData.unused || []),
          errorsCount = errors.length,
          stripRegexp = /^\s*(\S*(\s+\S+)*)\s*$/,
            // For use in stripping leading/trailing whitespace from a string
          error, i;

      // Sort errors by line number
      errors = errors.sort(function(errorA, errorB) {
        if (!errorA || !errorB || !errorA.line || !errorB.line) { return 0; }

        // If alert (e.g., "Too many errors"), force to be listed last.
        // `!errorA.name` implies that the error is not "Unused variable", and
        // `!errorA.evidence` implies that the error has no code context
        // ("evidence").
        if (!errorA.name && !errorA.evidence) { return  1; }
        if (!errorB.name && !errorB.evidence) { return -1; }

        return errorA.line - errorB.line;
      });

      // Format errors as readable strings
      for (i = 0; i < errorsCount; i++) {
        error = errors[i];
        if (error) {
          if (error.name) {
            print('Unused variable at line ' + error.line + ': ' +
              error.name);
          } else {
            print('Lint at line ' + error.line + ' character ' +
              error.character + ': ' + error.reason);
            print(error.evidence ?
              error.evidence.replace(stripRegexp, "$1") : '');
          }

          print('');
        }
      }
    }());

    quit(2);
  } else {
    print('No problems found.');
    quit();
  }
}(arguments));
