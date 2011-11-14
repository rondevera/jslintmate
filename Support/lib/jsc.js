// Processes a JS file with a lint tool, then prints human-readable
// descriptions of each error. Run this after `jslint.js` or `jshint.js` so
// that JSC can run it.
//
// More on JSC: https://trac.webkit.org/wiki/JSC
//
// Adapted from:
// - http://blog.pulletsforever.com/2009/07/09/running_jslint_with_safaris_javascript_core/
// - https://github.com/jshint/jshint/blob/master/env/rhino.js

/*
Copyright (c) 2002 Douglas Crockford (www.JSLint.com) JSC Edition
Copyright (c) 2009 Apple Inc.
*/

/*jslint  browser:  false,
          evil:     true,
          newcap:   true,
          nomen:    true,
          onevar:   true,
          plusplus: true,
          rhino:    true,
          sloppy:   true,
          white:    true */
/*global  JSLINT, JSHINT */



(function(args){
  // TODO: This has turned into one big function. Refactor.

  var filename  = args[0],
      linter    = (typeof JSHINT !== 'undefined' ? JSHINT : JSLINT),
      options   = args.slice(1), // Array; all but first
      linterOptions = {},
      linterData;

  function optionsStringToHash (string) {
    // Given a string '{a:1,b:[2,3],c:{d:4,e:5}}`, returns an object/hash.

    try {
      return string ? eval('(' + string + ')') : {};
        // Using `eval` because the input might not be valid JSON. Trusts that
        // any collaborators aren't messing with each other.
    } catch (e) {
      return {};
    }
  }

  function copyProperties (orig, overrides) {
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
  }

  function parseOptions (optionsArray) {
    // Given an array `optionsArray`, returns a hash where each array item
    // is split into a key and value. Linter options are also converted into
    // hashes.

    var options = {}, i, option, key, value;

    for (i = optionsArray.length; i--;) {
      // Split option (e.g., 'a=b=c') into key and value (e.g., 'a' and 'b=c')
      option = optionsArray[i];         // option = 'a=b=c'
      key    = option.split('=');       // key    = ['a', 'b', 'c']
      value  = key.slice(1).join('=');  // value  = 'b=c'
      key    = key[0];                  // key    = 'a'

      // Convert known linter options to hashes
      switch (key) {
        case '--linter-options-from-bundle':
        case '--linter-options-from-config-file':
        case '--linter-options-from-defaults':
          value = optionsStringToHash(value); break;
      }

      // Copy to hash
      options[key] = value;
    }

    return options;
  }


  // Check for JS code
  if(!filename){
    print('Usage: jsc (jslint|jshint).js jsc.js -- "$(cat myFile.js)"' +
          ' [--linter-options-from-bundle=\'a:1,b:[2,3]\']' +
          ' [--linter-options-from-config-file=\'c:4,d:{e:5,f:6}\']' +
          ' [--linter-options-from-defaults=\'g:7\']');
    quit(1);
  }

  // Parse arguments
  options = parseOptions(options); // Convert options from array to hash

  // Merge options                                  // Precedence:
  copyProperties(linterOptions,
    options['--linter-options-from-defaults']);     // <- lowest
  copyProperties(linterOptions,
    options['--linter-options-from-bundle']);
  copyProperties(linterOptions,
    options['--linter-options-from-config-file']);  // <- highest
    // The linter options in the target file override these
    // (i.e., have top precedence).

  // Run linter and fetch data
  linter(filename, linterOptions);
  linterData = linter.data();
  if(!linter.unused){
    // The key (`unused` or `unuseds`) varies across JSHint and various
    // versions of JSLint. Normalize as `unused`.
    linter.unused = linter.unuseds; // Value may be `null`
  }

  if(linterData.errors || linterData.unused){
    // Format errors
    (function(){
      var errors = (linter.errors || []).concat(linterData.unused || []),
          errorsCount = errors.length,
          stripRegexp = /^\s*(\S*(\s+\S+)*)\s*$/,
            // For use in stripping leading/trailing whitespace from a string
          error, i;

      // Sort errors by line number
      errors = errors.sort(function(errorA, errorB){
        if(!errorA || !errorB || !errorA.line || !errorB.line){ return 0; }

        // If alert (e.g., "Too many errors"), force to be listed last.
        // `!errorA.name` implies that the error is not "Unused variable", and
        // `!errorA.evidence` implies that the error has no code context
        // ("evidence").
        if(!errorA.name && !errorA.evidence){ return  1; }
        if(!errorB.name && !errorB.evidence){ return -1; }

        return errorA.line - errorB.line;
      });

      // Format errors as readable strings
      for(i = 0; i < errorsCount; i++){
        error = errors[i];
        if(error){
          if(error.name){
            print('Unused variable at line ' + error.line + ': ' +
              error.name);
          }else{
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
  }else{
    print('No problems found.');
    quit();
  }
}(arguments));
