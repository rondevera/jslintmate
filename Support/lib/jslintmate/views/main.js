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
  nav.scrollTo = function(y, duration) {
    // Usage:
    // - `nav.scrollTo(0)`    // => scroll to top
    // - `nav.scrollTo(100)`  // => scroll to 100px from top

    var container   = nav.scrollingContainer,
        oldPosition = container.scrollTop,
        newPosition = y,
        msPerFrame  = 20,
        frame, frames;
    if (duration === undefined) { duration = 500; } // milliseconds

    nav.clearScrollTimeouts();

    // Check if content is scrollable
    if (container.scrollHeight <= container.offsetHeight) {
      return;
    }

    if (duration > 0) {
      // Scroll with animation
      frames = Math.floor(duration / msPerFrame);
      for (frame = 0; frame <= frames; frame++) {
        nav.scrollTimeouts[frame] = setTimeout(
          nav.getScrollTimeoutCallback(
            frame / frames, oldPosition, newPosition - oldPosition),
          frame * msPerFrame
        );
      }
    } else {
      // Scroll immediately without animating
      nav.scrollingContainer.scrollTop = y;
    }
  };
  nav.getScrollTimeoutCallback = function(percent, origPosition, deltaPosition) {
    // Returns a callback for use with `setTimeout` to animate scrolling.
    // Arguments:
    // - `percent`:       Percentage of animation completion
    // - `origPosition`:  Original position before starting to scroll
    // - `deltaPosition`: Distance to scroll by the end of the whole animation

    return function() {
      nav.scrollingContainer.scrollTop = origPosition + (deltaPosition * (
        // Quintic ease out:
               Math.pow(percent, 5)  +
        ( -5 * Math.pow(percent, 4)) +
        ( 10 * Math.pow(percent, 3)) +
        (-10 * Math.pow(percent, 2)) +
        (  5 *          percent    )
      ));
    };
  };
  nav.clearScrollTimeouts = function() {
    var i;

    if (nav.scrollTimeouts) {
      i = nav.scrollTimeouts.length;
      while (i--) {
        clearTimeout(nav.scrollTimeouts[i]);
      }
    }
    nav.scrollTimeouts = [];
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
      nav.scrollTo(elemTopBound, 0);

    } else if (bodyScrollTop < elemBottomBound) {
      // If `elem` is outside of viewport (bottom edge is below bottom of
      // viewport), scroll to put it at bottom of viewport.
      nav.scrollTo(elemBottomBound, 0);
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
      var li = ev.target,
          liTagName = li.tagName.toLowerCase(),
          liCurrent;

      // Find closest `<li>`
      while (
          liTagName !== 'li' && // Search ancestors,
          liTagName !== 'ul'    // but not too far
        ) {
        li = li.parentNode;
        liTagName = li.tagName.toLowerCase();
      }

      // Only handle if `<li>` contains a problem item
      if (/alert/.test(li.className)) { return; }

      liCurrent = $qs('ul.problems li.' + nav.CUR);
      if (liCurrent) { liCurrent.className = ''; }
      li.className = nav.CUR;

      // Allow event to continue normally, i.e., follow the link's `href`
    }, false);
  }());

  // Open external links in browser
  d.body.addEventListener('click', function(ev) { // delegate
    var target = ev.target;

    if (target.tagName.toLowerCase() === 'a' &&
        target.href.indexOf('http') === 0
      ) {
      TextMate.system('open ' + target.href, null);
      ev.preventDefault();
    }
  });

  // Prevent dragging links
  d.body.addEventListener('mousedown', function(ev) { // delegate
    var target = ev.target;

    // Check if dragging a link or a child of a link. Given the DOM structure,
    // this doesn't need to check further.
    if (target.tagName.toLowerCase() === 'a' ||
        target.parentNode.tagName.toLowerCase() === 'a'
      ) {
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
