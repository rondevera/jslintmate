/*jslint browser: true */
/*global TextMate */

(function(d){
  // Handle link to bundle info
  (function(){
    var infoLink = (d.querySelectorAll('header a.info') || [])[0];
    if(!infoLink){ return; }

    infoLink.addEventListener('click', function(ev){
      var url = ev.target.href;
      TextMate.system('open ' + url, null); // Open in browser
      ev.preventDefault();
    });
  }());

  // Set up keyboard shortcuts
  d.addEventListener('keydown', function(ev){
    switch(ev.which){
      case 27: // escape
        window.close();
        ev.preventDefault();
        break;
    }
  }, false);
}(document));
