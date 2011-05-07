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
        items, i;

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

      // If `cur` is out of viewport (top edge is above top of viewport),
      // scroll to put it at top of viewport
      if(cur.offsetTop < d.body.scrollTop + Nav.headerHeight()){
        d.body.scrollTop = cur.offsetTop - Nav.headerHeight();
      }
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

      // If `cur` is out of viewport (bottom edge is below bottom of
      // viewport), scroll to put it at top of viewport
      if(cur.offsetTop + cur.offsetHeight > w.innerHeight + d.body.scrollTop){
        d.body.scrollTop = cur.offsetTop + cur.offsetHeight - w.innerHeight;
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
