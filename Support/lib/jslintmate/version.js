// Enables checking for newer versions and showing notifications.

/*jslint  browser:  true,
          sloppy:   true,
          white:    true */
/*jshint  white:    false */



window.jslm = (function(w, d) {
  var jslm    = w.jslm || {},
      version = jslm.version = {};

  version.getNewest = function() {
    // Retrieves the latest version number from GitHub. The JSON-P endpoint
    // calls `jslm.version.setNewest`.

    // This reads a static JS file from GitHub to determine the newest version
    // available. Feel free to instead fork this and host/update the version
    // JS on a server that you control.

    var versionURL  = 'http://rondevera.github.com/jslintmate/js/version-newest.js',
        firstScript = d.getElementsByTagName('script')[0],
        newScript   = d.createElement('script');

    newScript.async = 1;
    newScript.src   = versionURL;
    firstScript.parentNode.insertBefore(newScript, firstScript);
  };

  version.setNewest = function(newVersion) {
    // `newVersion` is a string, e.g., `1.1.1`, that should match the string
    // in the `VERSION` file.

    version.newest = newVersion;

    if (version.updateIsAvailable()) {
      version.showUpdate();
    }
  };

  version.showUpdate = function() {
    // Renders an update control in UI.

    var websiteLink = d.querySelector('header a.info'),
        updateLink  = d.createElement('a');

    updateLink.innerHTML = 'A new version is available!';
    updateLink.className = 'update';
    updateLink.href      = websiteLink.href;
    updateLink.title     = 'Download JSLintMate ' + version.newest;
    websiteLink.style.display = 'none';
    d.querySelector('header').appendChild(updateLink);
  };

  version.updateIsAvailable = function() {
    // Returns `true` if a newer version is available. This check assumes
    // that version numbers will always increase. If the version number in the
    // source repository decreases for any reason (e.g., rollback), it should
    // also take precedence over the current version.

    return version.current !== version.newest;
  };

  return jslm;
}(window, document));
