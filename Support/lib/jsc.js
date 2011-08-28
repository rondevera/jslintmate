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

/*jslint  newcap:   true,
          nomen:    true,
          onevar:   true,
          plusplus: true,
          rhino:    true,
          sloppy:   true,
          undef:    true,
          white:    true */
/*global  JSLINT, JSHINT */



(function(args){
  var filename  = args[0],
      options   = args[1],
      linter    = (typeof JSHINT !== 'undefined' ? JSHINT : JSLINT),
      linterOptions = {},
      linterData;

  // Check for JS code
  if(!filename){
    print('Usage: jsc (jslint|jshint).js jsc.js -- "$(cat myFile.js)" ' +
          '[opt1=val1,opt2=val2]');
    quit(1);
  }

  // Parse linter options
  if(options){
    options.split(',').forEach(function(opt){
      var kv = opt.split('='), k = kv[0], v = kv[1];

      linterOptions[k] = (
        // Ew, nested ternaries. Refactor if more complexity is needed.
        v === 'true'  ? true  : // Convert strings to
        v === 'false' ? false : // native booleans
        v
      );
    });
  }

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
