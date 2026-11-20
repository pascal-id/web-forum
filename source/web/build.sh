#!/bin/bash
mkdir -p lib/$(fpc -iTP)-$(fpc -iTO)
START=$(date +%s)

if [ -n "$1" ]; then
  PROJECTBASE=$1
  PROJECTBASE="${PROJECTBASE//.lp/}"
  PROJECTBASE="${PROJECTBASE//./}"
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
RESULT=$?

if [ -n "$HOST_UID" ]; then
  chown -R $HOST_UID:$HOST_GID lib 2>/dev/null
  chown $HOST_UID:$HOST_GID ../../public_html/$PROJECTBASE.bin 2>/dev/null
fi

echo ">> selesai dalam $(( $(date +%s) - START )) detik"
echo Done.... $1
echo

# propagate the compiler result (build-all.sh and CI can detect a failed build)
exit $RESULT
