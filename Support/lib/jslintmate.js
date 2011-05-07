/*jslint browser: true */
/*global TextMate */

(function(w, d){
  var Nav = {CUR: 'current'};

  function $qs(selector) { return d.querySelector(selector);    }
  function $qsa(selector){ return d.querySelectorAll(selector); }



  /*** Nav ***/

  Nav.getHighlighted = function(){
    return $qs('ul.problems li.' + Nav.CUR);
  };
  Nav.openHighlighted = function(){
    var curLink = $qs('ul.problems li.current a'),
        ev;

    if(!curLink){ return; }

    ev = d.createEvent('HTMLEvents');
    ev.initEvent('click', true,   // bubbling
                          true);  // cancelable
    curLink.dispatchEvent(ev);
  };
  Nav.highlightFirst = function(){
    $qs('ul.problems li').className = Nav.CUR;
    d.body.scrollTop = 0; // Scroll to top
  };
  Nav.highlightPrev = function(){
    var cur = Nav.getHighlighted(), prev,
        contentTop, items, i;

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

      // If `cur` is outside of viewport (top edge is above top of viewport),
      // scroll to put it at top of viewport
      contentTop = cur.offsetTop;
      if(contentTop < d.body.scrollTop + Nav.headerHeight()){
        d.body.scrollTop = contentTop - Nav.headerHeight();
      }
    }else{
      Nav.highlightFirst();
    }
  };
  Nav.highlightNext = function(){
    var cur = Nav.getHighlighted(), next,
        bottomElem, contentBottom;

    if(cur){
      next = $qs('ul.problems li.' + Nav.CUR + ' + li:not(.alert)');
      if(next){
        next.className = Nav.CUR;
        cur.className  = '';
        cur = next;
      }

      // If `cur` is outside of viewport (bottom edge is below bottom of
      // viewport), scroll to put it at top of viewport
      bottomElem    = $qs('ul.problems li.' + Nav.CUR + ' + li.alert') || cur;
      contentBottom = bottomElem.offsetTop + bottomElem.offsetHeight;
        // If next element is an alert (not selectable), use its bottom edge
        // in calculations; otherwise, use `cur`. This way, upon reaching
        // the bottom of the window, the alert is shown along with the final
        // selectable list item.

      if(contentBottom > w.innerHeight + d.body.scrollTop){
        d.body.scrollTop = contentBottom - w.innerHeight;
      }
    }else{
      Nav.highlightFirst();
    }
  };
  Nav.headerHeight = function(){
    if(typeof Nav.headerHeight._value === 'undefined'){
      Nav.headerHeight._value = d.querySelector('header').offsetHeight;
    }
    return Nav.headerHeight._value;
  };



  /*** Behaviors ***/

  // Handle link to bundle info
  (function(){
    var infoLink = d.querySelector('header a.info');
    if(!infoLink){ return; }

    infoLink.addEventListener('click', function(ev){
      var url = ev.target.href;
      TextMate.system('open ' + url, null); // Open in browser
      ev.preventDefault();
    });
  }());

  // Set up keyboard shortcuts
  if(d.querySelector('ul.problems')){
    d.addEventListener('keydown', function(ev){
      switch(ev.keyCode){
        case 13: // enter
          Nav.openHighlighted(); ev.preventDefault(); break;
        case 74: // 'j'
          Nav.highlightNext();   ev.preventDefault(); break;
        case 75: // 'k'
          Nav.highlightPrev();   ev.preventDefault(); break;
      }
    }, false);
  }

}(window, document));
