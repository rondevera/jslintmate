// Run this after jslint.js or jshint.js so that JSC can run it.
//
// Adapted from:
// - http://blog.pulletsforever.com/2009/07/09/running_jslint_with_safaris_javascript_core/
// - https://github.com/jshint/jshint/blob/master/env/rhino.js

/*
Copyright (c) 2002 Douglas Crockford (www.JSLint.com) JSC Edition
Copyright (c) 2009 Apple Inc.
*/

/*jslint  eqeqeq:   true,
          immed:    false,
          newcap:   true,
          nomen:    false,
          onevar:   true,
          plusplus: false,
          rhino:    true,
          undef:    true,
          white:    false */
/*global  JSLINT, JSHINT */

(function(args){
  var filename  = args[0],
      options   = args[1],
      linter    = (typeof JSHINT !== 'undefined' ? JSHINT : JSLINT),
      linterOptions = {};

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

  if(!linter(filename, linterOptions)){
    // Format errors
    (function(){
      var errorsCount = linter.errors.length,
          regexp = /^\s*(\S*(\s+\S+)*)\s*$/,
          i, e;

      for(i = 0; i < errorsCount; i++){
        e = linter.errors[i];
        if(e){
          print('Lint at line ' + (e.line + 1) + ' character ' +
            (e.character + 1) + ': ' + e.reason);
          print(e.evidence ? e.evidence.replace(regexp, "$1") : '');
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
