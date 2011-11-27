// Enables behaviors for the JSLintMate UI.

/*jslint  browser:  true,
          newcap:   true,
          nomen:    true,
          onevar:   true,
          plusplus: true,
          rhino:    true,
          sloppy:   true,
          white:    true */
/*jshint  nomen:    false,
          plusplus: false,
          white:    false */
/*global  TextMate */



window.jslm = (function(w, d){
  var jslm    = w.jslm || {},
      nav     = jslm.nav = {CUR: 'current'},
      support = jslm.support = {css: {}, elem: d.createElement('test')};
                  // For use in feature detection

  function $qs(selector) { return d.querySelector(selector);    }
  function $qsa(selector){ return d.querySelectorAll(selector); }

  support.css.insetBoxShadow = (function(){
    var elem = support.elem,
        prop = 'webkitBoxShadow';

    elem.style[prop] = 'inset 0 0 0 red';
    return typeof elem.style[prop] !== 'undefined' && elem.style[prop] !== '';
      // If `box-shadow: inset ...` is supported, the style string is updated
      // (though not necessarily to the given value). If `inset` is not
      // supported, the value is reset to an empty string. If
      // `-webkit-box-shadow` is not supported, the value is reset to
      // `undefined`.
  }());



  /*** Navigation ***/

  nav.headerHeight = function(){
    if(typeof nav.headerHeight._value === 'undefined'){
      nav.headerHeight._value = $qs('header').offsetHeight;
    }
    return nav.headerHeight._value;
  };

  /*** Navigation > Scrolling ***/

  nav.scrollTo = function(y){
    // Usage:
    // - `nav.scrollTo(0)`    // => scroll to top
    // - `nav.scrollTo(100)`  // => scroll to 100px from top
    d.body.scrollTop = y;
  };
  nav.scrollToShowElement = function(elem){
    elem = $qs('ul.problems li.' + nav.CUR + ' + li.alert') || elem;
      // If the next element is an alert (not selectable), use its bottom edge
      // in calculations; otherwise, use `elem`. This way, upon reaching the
      // bottom of the window, the alert is shown along with the final
      // selectable list item.

    var bodyScrollTop   = d.body.scrollTop,
        elemTop         = elem.offsetTop,
        elemBottom      = elem.offsetTop + elem.offsetHeight,
        elemTopBound    = elemTop - nav.headerHeight(),
        elemBottomBound = elemBottom - w.innerHeight;

    if(bodyScrollTop > elemTopBound){
      // If `elem` is outside of viewport (top edge is above top of viewport),
      // scroll to put it at top of viewport.
      nav.scrollTo(elemTopBound);

    }else if(bodyScrollTop < elemBottomBound){
      // If `elem` is outside of viewport (bottom edge is below bottom of
      // viewport), scroll to put it at bottom of viewport.
      nav.scrollTo(elemBottomBound);
    }
  };

  /*** Navigation > Highlighting ***/

  nav.getHighlighted = function(){
    return $qs('ul.problems li.' + nav.CUR);
  };
  nav.openHighlighted = function(){
    var curLink = $qs('ul.problems li.current a'),
        ev;

    if(!curLink){ return; }

    // Trigger a click on the currently selected problem
    ev = d.createEvent('HTMLEvents');
    ev.initEvent('click', true,   // bubbling
                          true);  // cancelable
    curLink.dispatchEvent(ev);
  };
  nav.highlightFirst = function(){
    $qs('ul.problems li').className = nav.CUR;
    nav.scrollTo(0); // Scroll to top
  };
  nav.highlightPrev = function(){
    var cur = nav.getHighlighted(), items, i;

    if(cur){
      // CSS3 can't select a previous sibling, so do this the long way.
      items = $qsa('ul.problems li:not(.alert)');
      i     = items.length;

      while(i--){
        if(items[i-1] && items[i].className === nav.CUR){
          cur = items[i-1];
          cur.className = nav.CUR;
          items[i].className = '';
          break;
        }
      }

      nav.scrollToShowElement(cur);
    }else{
      nav.highlightFirst();
    }
  };
  nav.highlightNext = function(){
    var cur = nav.getHighlighted(), next;

    if(cur){
      next = $qs('ul.problems li.' + nav.CUR + ' + li:not(.alert)');

      if(next){
        next.className = nav.CUR;
        cur.className  = '';
        cur = next;
      }

      nav.scrollToShowElement(cur);
    }else{
      nav.highlightFirst();
    }
  };



  /*** Appearance ***/

  // Add styling hook to `<html>`:
  if(support.css.insetBoxShadow){
    d.documentElement.setAttribute('data-css-inset-box-shadow', 1);
  }



  /*** Behaviors ***/

  // Handle clicks on problem items
  (function(){
    var problemsList = $qs('ul.problems');

    if (!problemsList) { return; }

    problemsList.addEventListener('click', function(ev){
      var link = ev.target,
          linkTagName = link.tagName.toLowerCase(),
          li, liCur;

      // If not `<a>`, find it in ancestors
      while(
          linkTagName !== 'a' && // Search up tree,
          linkTagName !== 'ul'   // but not too far
        ){
        link = link.parentNode;
        linkTagName = link.tagName.toLowerCase();
      }

      li    = link.parentNode;
      liCur = $qs('ul.problems li.' + nav.CUR);
      if(liCur){ liCur.className = ''; }
      li.className = nav.CUR;

      // Allow event to continue normally, i.e., follow the link's `href`
    }, false);
  }());

  // Handle link to bundle info
  (function() {
    var header = $qs('header');
    if (!header) { return; }

    header.addEventListener('click', function(ev) { // delegate
      var target = ev.target;

      if (target.tagName.toLowerCase() === 'a' &&
          (target.className === 'info' || target.className === 'update')
        ) {
        TextMate.system('open ' + target.href, null); // Open in browser
        ev.preventDefault();
      }
    }, false);
  }());

  // Set up keyboard shortcuts
  if($qs('ul.problems')){
    d.addEventListener('keydown', function(ev){
      switch(ev.keyCode){
        case 13: // enter
          nav.openHighlighted(); ev.preventDefault(); break;
        case 40: // down arrow
        case 74: // 'j'
          nav.highlightNext();   ev.preventDefault(); break;
        case 38: // up arrow
        case 75: // 'k'
          nav.highlightPrev();   ev.preventDefault(); break;
      }
    }, false);
  }

  // Check for updates
  setTimeout(function() {
    if (jslm.version) { jslm.version.getNewest(); }
  }, 10e3);



  return jslm;
}(window, document));
