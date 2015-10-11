#!/bin/bash

find . -type 'f' -exec chmod 600 \{\} \;
find . -type 'f' -name '*.sh' -exec chmod 700 \{\} \;
find . -type 'f' -name '*.sub' -exec chmod 700 \{\} \;
find . -type 'f' -path '*/bin/*' -exec chmod 700 \{\} \;
find . -type 'd' -exec chmod 700 \{\} \;
