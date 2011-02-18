#!/bin/bash

# First step, done manually:
# sudo git clone git://github.com/rondevera/jslintmate.git /usr/local/src/jslintmate/

# Download JSLint
mkdir ~/Library/JSLint
curl http://www.JSLint.com/fulljslint.js > ~/Library/JSLint/fulljslint.js

# Add JSC adapter to let fulljslint.js accept arguments
cat /usr/local/src/jslintmate/fulljslint-jsc.js >> ~/Library/JSLint/fulljslint.js

# Install the TextMate command
open /usr/local/src/jslintmate/JSLint.tmCommand
