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

(function (a) {
  var linter = (typeof JSHINT !== 'undefined' ? JSHINT : JSLINT),
      linterOptions = {};

  // Check for JS code
  if (!a[0]) {
    print('Usage: jsc (jslint|jshint).js jsc.js -- "$(cat myFile.js)" ' +
          '[--linter-options=opt1=val1,opt2=val2]');
    quit(1);
  }

  // Parse linter options
  if(a[1]){
    a[1].split(',').forEach(function(opt){
      var kv = opt.split('='), k = kv[0], v = kv[1];
      linterOptions[k] = (function(){
        switch(v){
          case 'true':  return true;
          case 'false': return false;
          default:      return v;
        }
      })();
    });
  }

  if (!linter(a[0], linterOptions)) {
    (function(){
      var errorsCount = linter.errors.length, i, e;
      for (i = 0; i < errorsCount; i += 1) {
        e = linter.errors[i];
        if (e) {
          print('Lint at line ' + (e.line + 1) + ' character ' +
            (e.character + 1) + ': ' + e.reason);
          print((e.evidence || '').replace(/^\s*(\S*(\s+\S+)*)\s*$/, "$1"));
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
