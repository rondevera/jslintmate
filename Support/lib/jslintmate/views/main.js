// Enables behaviors for the JSLintMate UI.

/*jslint  browser:  true,
          newcap:   true,
          nomen:    true,
          plusplus: true,
          rhino:    true,
          sloppy:   true,
          vars:     false,
          white:    true */
/*jshint  nomen:    false,
          plusplus: false,
          white:    false */
/*global  TextMate */



window.jslm = (function(w, d) {
  var jslm    = w.jslm || {},
      nav     = jslm.nav = {CUR: 'current'},
      support = jslm.support = {css: {}, elem: d.createElement('test')};
                  // For use in feature detection

  function $qs(selector)  { return d.querySelector(selector);    }
  function $qsa(selector) { return d.querySelectorAll(selector); }

  support.css.insetBoxShadow = (function() {
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

  nav.headerHeight = function() {
    return $qs('header').offsetHeight;
  };

  /*** Navigation > Scrolling ***/

  nav.scrollingContainer = $qs('div.results');
  nav.scrollTo = function(y) {
    // Usage:
    // - `nav.scrollTo(0)`    // => scroll to top
    // - `nav.scrollTo(100)`  // => scroll to 100px from top
    nav.scrollingContainer.scrollTop = y;
  };
  nav.scrollToTop = function() {
    nav.scrollTo(0);
  };
  nav.scrollToBottom = function() {
    nav.scrollTo(nav.scrollingContainer.scrollHeight);
  };
  nav.scrollByPage = function(numPages) {
    // Usage:
    // - `nav.scrollByPage(2)`  // scroll down (forward) by two pages
    // - `nav.scrollByPage(-2)` // scroll up (backward) by two pages

    var container       = nav.scrollingContainer,
        currentPosition = container.scrollTop,
        pageHeight      = container.offsetHeight,
        itemHeight      = container.querySelector('li').offsetHeight + 1,
                            // `+ 1`: Border width
        pageIncrement   = itemHeight * Math.floor(pageHeight / itemHeight);
                            // `Math.floor`: After scrolling, the first item in
                            // view should be completely visible, not partially.

    nav.scrollTo(currentPosition + (numPages * pageIncrement));
  };
  nav.scrollToNextPage = function() { nav.scrollByPage( 1); };
  nav.scrollToPrevPage = function() { nav.scrollByPage(-1); };
  nav.scrollToShowElement = function(elem) {
    elem = $qs('ul.problems li.' + nav.CUR + ' + li.alert') || elem;
      // If the next element is an alert (not selectable), use its bottom edge
      // in calculations; otherwise, use `elem`. This way, upon reaching the
      // bottom of the window, the alert is shown along with the final
      // selectable list item.

    var bodyScrollTop   = nav.scrollingContainer.scrollTop,
        elemTop         = elem.offsetTop,
        elemBottom      = elem.offsetTop + elem.offsetHeight,
        elemTopBound    = elemTop,
        elemBottomBound = elemBottom - nav.scrollingContainer.offsetHeight;

    if (bodyScrollTop > elemTopBound) {
      // If `elem` is outside of viewport (top edge is above top of viewport),
      // scroll to put it at top of viewport.
      nav.scrollTo(elemTopBound);

    } else if (bodyScrollTop < elemBottomBound) {
      // If `elem` is outside of viewport (bottom edge is below bottom of
      // viewport), scroll to put it at bottom of viewport.
      nav.scrollTo(elemBottomBound);
    }
  };

  /*** Navigation > Highlighting ***/

  nav.getHighlighted = function() {
    return $qs('ul.problems li.' + nav.CUR);
  };
  nav.openHighlighted = function() {
    var curLink = $qs('ul.problems li.current a'),
        ev;

    if (!curLink) { return; }

    // Trigger a click on the currently selected problem
    ev = d.createEvent('HTMLEvents');
    ev.initEvent('click', true,   // bubbling
                          true);  // cancelable
    curLink.dispatchEvent(ev);
  };
  nav.highlightFirst = function() {
    $qs('ul.problems li').className = nav.CUR;
    nav.scrollTo(0); // Scroll to top
  };
  nav.highlightLast = function() {
    var items = $qsa('ul.problems li:not(.alert)'),
        cur   = items[items.length - 1];

    cur.className = nav.CUR;
    nav.scrollToShowElement(cur);
  };
  nav.highlightPrev = function() {
    var cur = nav.getHighlighted(), items, i;

    if (cur) {
      // CSS3 can't select a previous sibling, so do this the long way.
      items = $qsa('ul.problems li:not(.alert)');
      i     = items.length;

      while (i--) {
        if (items[i-1] && items[i].className === nav.CUR) {
          cur = items[i-1];
          cur.className = nav.CUR;
          items[i].className = '';
          break;
        }
      }

      nav.scrollToShowElement(cur);
    } else {
      nav.highlightLast();
    }
  };
  nav.highlightNext = function() {
    var cur = nav.getHighlighted(), next;

    if (cur) {
      next = $qs('ul.problems li.' + nav.CUR + ' + li:not(.alert)');

      if (next) {
        next.className = nav.CUR;
        cur.className  = '';
        cur = next;
      }

      nav.scrollToShowElement(cur);
    } else {
      nav.highlightFirst();
    }
  };
  nav.highlightNone = function() {
    var cur = nav.getHighlighted();
    if (cur) { cur.className = ''; }
  };



  /*** Appearance ***/

  // Push results (success/error/problems) below header and notices
  (function() {
    var resizeTimeout;

    function repositionResults() {
      $qs('div.results').style.top = nav.headerHeight() + 'px';
      resizeTimeout = null;
    }

    repositionResults();

    window.addEventListener('resize', function() {
      // Throttle resize events
      if (!resizeTimeout) {
        resizeTimeout = setTimeout(repositionResults, 100);
      }
    }, false);
  }());

  // Add styling hook to `<html>`:
  if (support.css.insetBoxShadow) {
    d.documentElement.setAttribute('data-css-inset-box-shadow', 1);
  }



  /*** Behaviors ***/

  // Handle clicks on problem items
  (function() {
    var problemsList = $qs('ul.problems');

    if (!problemsList) { return; }

    problemsList.addEventListener('click', function(ev) {
      var link = ev.target,
          linkTagName = link.tagName.toLowerCase(),
          li, liCur;

      // If not `<a>`, find it in ancestors
      while (
          linkTagName !== 'a' && // Search up tree,
          linkTagName !== 'ul'   // but not too far
        ) {
        link = link.parentNode;
        linkTagName = link.tagName.toLowerCase();
      }

      li    = link.parentNode;
      liCur = $qs('ul.problems li.' + nav.CUR);
      if (liCur) { liCur.className = ''; }
      li.className = nav.CUR;

      // Allow event to continue normally, i.e., follow the link's `href`
    }, false);
  }());

  // Handle external links
  d.body.addEventListener('click', function(ev) { // delegate
    var target = ev.target;

    if (target.tagName.toLowerCase() === 'a' &&
        target.href.indexOf('http') === 0
      ) {
      TextMate.system('open ' + target.href, null); // Open in browser
      ev.preventDefault();
    }
  });

  // Set up keyboard shortcuts
  if ($qs('ul.problems')) {
    d.addEventListener('keydown', function(ev) {
      switch (ev.keyCode) {
        case 13: // enter
          nav.openHighlighted();  ev.preventDefault(); break;
        case 40: // down arrow
        case 74: // 'j'
          nav.highlightNext();    ev.preventDefault(); break;
        case 38: // up arrow
        case 75: // 'k'
          nav.highlightPrev();    ev.preventDefault(); break;
        case 27: // escape
          nav.highlightNone();    ev.preventDefault(); break;
        case 36: // home
          nav.scrollToTop();      ev.preventDefault(); break;
        case 35: // end
          nav.scrollToBottom();   ev.preventDefault(); break;
        case 33: // page up
          nav.scrollToPrevPage(); ev.preventDefault(); break;
        case 34: // page down
          nav.scrollToNextPage(); ev.preventDefault(); break;
      }
    }, false);
  }

  // Check for updates
  setTimeout(function() {
    if (jslm.version) { jslm.version.getNewest(); }
  }, 10e3);



  return jslm;
}(window, document));
