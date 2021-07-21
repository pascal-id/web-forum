#!/bin/bash
if [ -n "$1" ]; then
  PROJECTBASE=$1
  PROJECTBASE="${PROJECTBASE//.lp/}"
  PROJECTFILE=$PROJECTBASE.lpr
  echo "Project: "$PROJECTBASE
else
  echo "USAGE:"
  echo "  ./build.sh yourproject"
  exit 0
fi

# is project file exists?
if [ ! -f $PROJECTFILE ]; then
    echo "Project File ($PROJECTFILE) not found!"
    exit 1
fi

if [ ! -d lib ]; then
    mkdir lib
fi

#fpc $PROJECTFILE @extra.cfg -o../../public_html/$PROJECTBASE.bin
#fpc $PROJECTFILE @extra.cfg -o../../public_html/$PROJECTBASE.bin -Tlinux
fpc $PROJECTFILE @extra.cfg -o../../public_html/$PROJECTBASE.bin $2

echo Done.... $1
echo
