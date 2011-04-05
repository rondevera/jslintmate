#!/usr/bin/env ruby

# Quick, simple JSLint in TextMate. Hurt your feelings in style.
# (JSLint.com is a powerful JS code quality tool.)

# Usage (in a TextMate bundle):
#
#   ruby '/path/to/jslintmate.rb' <options>
#
# Options:
#
#   --linter          'jslint' (default) or 'jshint'
#   --linter-options  Format: 'option1=value1,option2=value'
#
# To update jslint.js and jshint.js:
#
#   cd /path/to/JSLintMate.tmbundle/Support/lib/
#   curl -o jslint.js http://www.jslint.com/fulljslint.js
#   curl -o jshint.js http://jshint.com/jshint.js

require 'cgi'

# Parse Ruby arguments
args = ARGV.inject({}) do |hsh, s|
  k, v = s.split('=', 2)
  k.sub!(/^--/, '')
  hsh.merge(k => v)
end
linter_name    = args['linter'] == 'jshint' ? 'jshint' : 'jslint'
linter_options = args['linter-options'] || 'undef=true'
linter_options_filepath = args['linter-options-file']

link_to_jslintmate = %{
  <a href="https://github.com/rondevera/jslintmate" class="info"
    title="More info on JSLintMate">info</a>
}.strip.split.join(' ')

if ENV['TM_FILEPATH']
  filepath = ENV['TM_FILEPATH']
  problems_count = 0

  # Prepare linter options
  if linter_options_filepath
    require 'yaml'

    # Convert any existing linter options to a hash
    linter_options =  if linter_options
                        linter_options.split(',').inject({}) do |hsh, kv|
                          k, v = kv.split('='); hsh.merge(k => v)
                        end
                      else
                        {}
                      end

    # Parse linter options file
    linter_options.merge!(
      YAML.load_file(linter_options_filepath).reject{ |k, v| v.is_a?(Array) })

    # Stringify linter options in `a=1,b=2` format
    linter_options =
      linter_options.inject([]) { |a, (k, v)| a << "#{k}=#{v}" }.join(',')
  end

  # Prepare OS X's JSC
  linter  = "#{ENV['TM_BUNDLE_SUPPORT']}/lib/#{linter_name}.js"
  jsc     = "#{ENV['TM_BUNDLE_SUPPORT']}/lib/jsc.js"
  cmd     = '/System/Library/Frameworks/JavaScriptCore.framework/' <<
             %{Versions/A/Resources/jsc "#{linter}" "#{jsc}" -- } <<
             %{"$(cat "#{filepath}")"}
  cmd     << %{ "#{linter_options}"} if linter_options
  lint    = `#{cmd}` # Find problems

  # If you prefer to use Rhino (Mozilla's open-source JS engine):
  #
  # A.  Install Rhino:
  #     1.  curl ftp://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R2.zip > /tmp/rhino1_7R2.zip
  #     2.  cd /tmp
  #     3.  unzip rhino1_7R2.zip
  #     4.  mkdir -p ~/Library/Java/Extensions
  #     5.  mv /tmp/rhino1_7R2/js.jar ~/Library/Java/Extensions/
  #
  # B.  Install JSLint:
  #     1.  mkdir ~/Library/JSLint
  #     2.  curl http://jslint.com/rhino/fulljslint.js > ~/Library/JSLint/fulljslint-rhino.js
  #
  # C.  Modify this script to use Rhino. Disable the JSC lines above, and
  #     use the following instead:
  #
  #         linter = '~/Library/JSLint/fulljslint-rhino.js'
  #         lint   = `java org.mozilla.javascript.tools.shell.Main #{linter} "#{filepath}"`
  #
  # See also: http://www.phpied.com/installing-rhino-on-mac/

  # Format problems
  lint.gsub!(/^(Lint at line )(\d+)(.+?:)(.+?)\n(?:(.+?)\n\n)?/m) do
    line, char, desc, code = $2, $3, $4, $5

    line = (line.to_i - 1).to_s
    char = (char.scan(/\d+/)[0].to_i - 1).to_s
    line_uri = "txmt://open?url=file://#{filepath}" <<
               "&line=#{CGI.escapeHTML(line)}&column=#{CGI.escapeHTML(char)}"
    desc = %{<span class="desc">#{CGI.escapeHTML(desc).strip}</span>} if desc
    loc  = %{<span class="location">#{
              CGI.escapeHTML("Line #{line}, character #{char}")}</span>}
    code = %{<pre>#{CGI.escapeHTML(code).strip}</pre>} if code

    if code
      problems_count += 1
      %{<li><a href="#{line_uri}">#{loc} #{desc} #{code}</a></li>}
    else
      %{<li class="alert">#{loc} #{desc}</li>}
    end
  end

  if lint =~ /No problems found/
    # Douglas Crockford would be so proud.
    result = %{
      <header>
        Lint-free! <span class="filepath">#{filepath}</span>
        #{link_to_jslintmate}
      </header>
      <p class="success">Lint-free!</p>
    }
  else
    result = %{
      <header>
        Problem#{'s' if problems_count > 1} found in:
        <span class="filepath">#{filepath}</span>
        #{link_to_jslintmate}
      </header>
      <ul class="problems">#{lint}</ul>
    }
  end
else # !ENV['TM_FILEPATH']
  result = %{
    <header>
      Oops!
      #{link_to_jslintmate}
    </header>
    <p class="alert">
      Please save this file before JSLint can hurt your feelings.
    </p>
  }
end

result.strip!

print <<HTML
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>JSLintMate#{' (with JSHint)' if linter_name == 'jshint'}</title>
  <style>
    html, body {
      margin: 0;
      padding: 0;
    }
    body {
      overflow: auto;
      overflow-x: hidden;
        background: -webkit-gradient(linear, left top, left bottom,
                                            from(#ececec), to(#d2d2d2));
        background: -webkit-linear-gradient(top, #ececec,     #d2d2d2);
      background:           linear-gradient(top, #ececec,     #d2d2d2);
      background-attachment: fixed;
      font-family: "Lucida Grande", "Helvetica Neue", Helvetica, sans-serif;
    }
    header {
      position: fixed;
      left: 0;
      top: 0;
      display: block;
      width: 100%;
      height: 2em;
      padding: 0.6667em;
      background: -webkit-gradient(linear, left top, left bottom, from(#333), color-stop(0.5, #191919), color-stop(0.5, #090909), to(#090909));
      background: -webkit-linear-gradient(top, #333, 0.5 #191919, 0.5 #090909, #090909);
      background:         linear-gradient(top, #333, 0.5 #191919, 0.5 #090909, #090909);
      border-top: 1px solid #555;
      border-bottom: 1px solid #333;
        -webkit-box-shadow: 0 2px 5px rgba(0, 0, 0, 0.25);
      box-shadow:           0 2px 5px rgba(0, 0, 0, 0.25);
      color: #fff;
      font-size: 1.5em;
      text-shadow: 0 -1px 1px #000;
      z-index: 9;
    }
    header .filepath {
      display: block;
      width: 95%;
      overflow: hidden;
      color: rgba(255, 255, 255, 0.5);
      font-size: 0.5833em;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    header a.info {
      position: absolute;
      right: 35px;
      top: 5px;
      display: block;
      width: 13px;
      height: 13px;
      background: transparent url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAABGdBTUEAANjr9RwUqgAAACBjSFJNAABtmAAAbZgAAAAAAABtmAAAAAAAAG2YAAAAAAAAbZhH+0sNAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAfklEQVQokWP8//8/A6mAiWQdBDQpMDAwvGdgYOinik0sBGwyZGBgeIAh8///f3Qs8P////P/IeA9FnmszstnYGCYiM952DQ1MjAwCEDZG4jVxMDAwOAPpTeSoskBSn9gYGAowJDFERDvoQGxH8pHUcOIIxkpQPEBbJK4NOEFAAWhZQnFaJuvAAAAAElFTkSuQmCC) 0 0 no-repeat;
        /* Image from Dashboard Widget resources in OS X */
        -webkit-border-radius: 7px;
      border-radius:           7px;
      opacity: 0;
      text-indent: -999em;
        -webkit-transition: background-color 0.1s linear, opacity 0.25s linear;
      transition:           background-color 0.1s linear, opacity 0.25s linear;
    }
    html:hover header a.info {
      opacity: 1;
    }
    header a.info:hover,
    header a.info:focus {
      background-color: rgba(255, 255, 255, 0.25);
    }
    p {
      margin: 0;
      text-shadow: 0 1px 1px #fff;
    }
    p.success {
      margin: 25% auto 0;
      padding: 138px 0 0;
      background: transparent url(data:image/png;base64,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) center top no-repeat;
        /* Image from Installer.app in OS X */
      font-size: 2em;
      font-weight: bold;
      text-align: center;
    }
    p.alert {
      margin: 2em;
      padding: 1em;
      background: -webkit-gradient(linear, left top, left bottom,
                                          from(#900), to(#600));
      background: -webkit-linear-gradient(top, #900,     #600);
      background:         linear-gradient(top, #900,     #600);
      border: 2px solid #300;
        -webkit-border-radius: 8px;
      border-radius:           8px;
      color: #fff;
      text-shadow: 0 -1px 1px rgba(0, 0, 0, 0.75);
    }
    ul.problems {
      margin: 0;
      padding: 5em 0 0;
      list-style: none;
    }
    ul.problems li {
      margin: 0;
    }
    ul.problems li.alert {
      margin: 0;
      padding: 1em;
      background-color: #933;
        /* CSS3 stripes: http://leaverou.me/2010/12/checkered-stripes-other-background-patterns-with-css3-gradients/ */
        background-image: -webkit-gradient(linear, 0 0, 100% 100%,
          from(            rgba(0, 0, 0, 0.1)),
          color-stop(0.25, rgba(0, 0, 0, 0.1)),
          color-stop(0.25, transparent       ),
          color-stop(0.5,  transparent       ),
          color-stop(0.5,  rgba(0, 0, 0 ,0.1)),
          color-stop(0.75, rgba(0, 0, 0, 0.1)),
          color-stop(0.75, transparent       ),
          to(              transparent       ));
        background-image: -webkit-linear-gradient(-45deg, rgba(0, 0, 0, 0.25), rgba(0, 0, 0, 0.25) 25%, transparent 25%, transparent 50%, rgba(0, 0, 0 ,0.25) 50%, rgba(0, 0, 0, 0.25) 75%, transparent 75%, transparent);
      background-image:           linear-gradient(-45deg, rgba(0, 0, 0, 0.25), rgba(0, 0, 0, 0.25) 25%, transparent 25%, transparent 50%, rgba(0, 0, 0 ,0.25) 50%, rgba(0, 0, 0, 0.25) 75%, transparent 75%, transparent);
        -webkit-background-size: 100px 100px;
      background-size:           100px 100px;
      border: 0;
        -webkit-box-shadow: inset 0 5px 10em #000;
      box-shadow:           inset 0 5px 10em #000;
      color: #fff;
      text-shadow: 0 2px 5px #000;
    }
    ul.problems a {
      display: block;
      background: -webkit-gradient(linear, left top, left bottom,
                                          from(#ececec), to(#d2d2d2));
      background: -webkit-linear-gradient(top, #ececec,     #d2d2d2);
      background:         linear-gradient(top, #ececec,     #d2d2d2);
      border-top: 1px solid #f9f9f9;
      border-bottom: 1px solid #ccc;
      color: #000;
      padding: 0.75em 1em 0.25em;
      text-decoration: none;
      text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5);
    }
    ul.problems a:hover {
      background: -webkit-gradient(linear, left top, left bottom,
                                          from(#648bf3), to(#1d60f1));
      background: -webkit-linear-gradient(top, #648bf3,     #1d60f1);
      background:         linear-gradient(top, #648bf3,     #1d60f1);
      border-top-color: #6187ef;
      border-bottom-color: #165bec;
      color: #fff;
      text-shadow: 0 1px 0 rgba(0, 0, 0, 0.5);
    }
    ul.problems .location {
      float: right;
      color: rgba(0, 0, 0, 0.5);
      font-size: 0.75em;
      text-transform: lowercase;
    }
    ul.problems li.alert .location {
      color: rgba(255, 255, 255, 0.75);
    }
    ul.problems a:hover .location {
      color: rgba(255, 255, 255, 0.75);
    }
    ul.problems .desc {
      display: block;
      margin-right: 10em;
      padding: 0 4px;
    }
    ul.problems pre {
      margin-top: 2px;
      padding: 2px 4px;
      overflow: hidden;
      background: -webkit-gradient(linear, left top, left bottom,
        from(           rgba(255, 255, 255, 0.25)),
        color-stop(0.5, rgba(255, 255, 255, 0.2 )),
        color-stop(0.5, rgba(255, 255, 255, 0.15)),
        to(             rgba(255, 255, 255, 0.1 )));
      background: -webkit-linear-gradient(top, rgba(255, 255, 255, 0.25), 0.5 rgba(255, 255, 255, 0.2), 0.5 rgba(255, 255, 255, 0.15), rgba(255, 255, 255, 0.1));
      background:         linear-gradient(top, rgba(255, 255, 255, 0.25), 0.5 rgba(255, 255, 255, 0.2), 0.5 rgba(255, 255, 255, 0.15), rgba(255, 255, 255, 0.1));
      border: 1px solid rgba(0, 0, 0, 0.05);
        -webkit-border-radius: 4px;
      border-radius:           4px;
        -webkit-box-shadow: 0 1px 0 rgba(255, 255, 255, 0.25);
      box-shadow:           0 1px 0 rgba(255, 255, 255, 0.25);
      font-family: Monaco, monospace;
      font-size: 12px;
      text-overflow: ellipsis;
    }
    ul.problems a:hover pre {
      background: -webkit-gradient(linear, left top, left bottom,
        from(           rgba(0, 0, 0, 0.05)),
        color-stop(0.5, rgba(0, 0, 0, 0.1 )),
        color-stop(0.5, rgba(0, 0, 0, 0.15)),
        to(             rgba(0, 0, 0, 0.2 )));
      background: -webkit-linear-gradient(top, rgba(0, 0, 0, 0.05), 0.5 rgba(0, 0, 0, 0.1), 0.5 rgba(0, 0, 0, 0.15), rgba(0, 0, 0, 0.2));
      background:         linear-gradient(top, rgba(0, 0, 0, 0.05), 0.5 rgba(0, 0, 0, 0.1), 0.5 rgba(0, 0, 0, 0.15), rgba(0, 0, 0, 0.2));
      border-color: rgba(0, 0, 0, 0.05);
        -webkit-box-shadow: 0 1px 0 rgba(255, 255, 255, 0.15);
      box-shadow:           0 1px 0 rgba(255, 255, 255, 0.15);
    }
  </style>
</head>
<body>
  #{result}
</body>
<script>
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
</script>
</html>
HTML
