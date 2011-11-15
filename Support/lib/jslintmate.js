// Enables behaviors for the JSLintMate UI.

/*jslint  browser:  true,
          newcap:   true,
          nomen:    true,
          onevar:   true,
          plusplus: true,
          rhino:    true,
          sloppy:   true,
          white:    true */
/*global  TextMate */



(function(w, d){
  var Nav     = {CUR: 'current'},
      Support = {css: {}, elem: d.createElement('test')};
        // For use in feature detection

  function $qs(selector) { return d.querySelector(selector);    }
  function $qsa(selector){ return d.querySelectorAll(selector); }

  Support.css.insetBoxShadow = (function(){
    var elem = Support.elem,
        prop = 'webkitBoxShadow';

    elem.style[prop] = 'inset 0 0 0 red';
    return typeof elem.style[prop] !== 'undefined' && elem.style[prop] !== '';
      // If `box-shadow: inset ...` is supported, the style string is updated
      // (though not necessarily to the given value). If `inset` is not
      // supported, the value is reset to an empty string. If
      // `-webkit-box-shadow` is not supported, the value is reset to
      // `undefined`.
  }());



  /*** Nav ***/

  Nav.headerHeight = function(){
    if(typeof Nav.headerHeight._value === 'undefined'){
      Nav.headerHeight._value = $qs('header').offsetHeight;
    }
    return Nav.headerHeight._value;
  };

  /*** Nav > Scrolling ***/

  Nav.scrollTo = function(y){
    // Usage:
    // - `Nav.scrollTo(0)`    // => scroll to top
    // - `Nav.scrollTo(100)`  // => scroll to 100px from top
    d.body.scrollTop = y;
  };
  Nav.scrollToShowElement = function(elem){
    elem = $qs('ul.problems li.' + Nav.CUR + ' + li.alert') || elem;
      // If the next element is an alert (not selectable), use its bottom edge
      // in calculations; otherwise, use `elem`. This way, upon reaching the
      // bottom of the window, the alert is shown along with the final
      // selectable list item.

    var bodyScrollTop   = d.body.scrollTop,
        elemTop         = elem.offsetTop,
        elemBottom      = elem.offsetTop + elem.offsetHeight,
        elemTopBound    = elemTop - Nav.headerHeight(),
        elemBottomBound = elemBottom - w.innerHeight;

    if(bodyScrollTop > elemTopBound){
      // If `elem` is outside of viewport (top edge is above top of viewport),
      // scroll to put it at top of viewport.
      Nav.scrollTo(elemTopBound);

    }else if(bodyScrollTop < elemBottomBound){
      // If `elem` is outside of viewport (bottom edge is below bottom of
      // viewport), scroll to put it at bottom of viewport.
      Nav.scrollTo(elemBottomBound);
    }
  };

  /*** Nav > Highlighting ***/

  Nav.getHighlighted = function(){
    return $qs('ul.problems li.' + Nav.CUR);
  };
  Nav.openHighlighted = function(){
    var curLink = $qs('ul.problems li.current a'),
        ev;

    if(!curLink){ return; }

    // Trigger a click on the currently selected problem
    ev = d.createEvent('HTMLEvents');
    ev.initEvent('click', true,   // bubbling
                          true);  // cancelable
    curLink.dispatchEvent(ev);
  };
  Nav.highlightFirst = function(){
    $qs('ul.problems li').className = Nav.CUR;
    Nav.scrollTo(0); // Scroll to top
  };
  Nav.highlightPrev = function(){
    var cur = Nav.getHighlighted(), items, i;

    if(cur){
      // CSS3 can't select a previous sibling, so do this the long way.
      items = $qsa('ul.problems li:not(.alert)');
      i     = items.length;

      while(i--){
        if(items[i-1] && items[i].className === Nav.CUR){
          cur = items[i-1];
          cur.className = Nav.CUR;
          items[i].className = '';
          break;
        }
      }

      Nav.scrollToShowElement(cur);
    }else{
      Nav.highlightFirst();
    }
  };
  Nav.highlightNext = function(){
    var cur = Nav.getHighlighted(), next;

    if(cur){
      next = $qs('ul.problems li.' + Nav.CUR + ' + li:not(.alert)');

      if(next){
        next.className = Nav.CUR;
        cur.className  = '';
        cur = next;
      }

      Nav.scrollToShowElement(cur);
    }else{
      Nav.highlightFirst();
    }
  };



  /*** Appearance ***/

  // Add styling hook to `<html>`:
  if(Support.css.insetBoxShadow){
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
      liCur = $qs('ul.problems li.' + Nav.CUR);
      if(liCur){ liCur.className = ''; }
      li.className = Nav.CUR;

      // Allow event to continue normally, i.e., follow the link's `href`
    }, false);
  }());

  // Handle link to bundle info
  (function(){
    var infoLink = $qs('header a.info');
    if(!infoLink){ return; }

    infoLink.addEventListener('click', function(ev){
      var url = ev.target.href;
      TextMate.system('open ' + url, null); // Open in browser
      ev.preventDefault();
    });
  }());

  // Set up keyboard shortcuts
  if($qs('ul.problems')){
    d.addEventListener('keydown', function(ev){
      switch(ev.keyCode){
        case 13: // enter
          Nav.openHighlighted(); ev.preventDefault(); break;
        case 40: // down arrow
        case 74: // 'j'
          Nav.highlightNext();   ev.preventDefault(); break;
        case 38: // up arrow
        case 75: // 'k'
          Nav.highlightPrev();   ev.preventDefault(); break;
      }
    }, false);
  }

}(window, document));
