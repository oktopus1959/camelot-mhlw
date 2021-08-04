#! /bin/bash

BINDIR=$(dirname $0)

. $BINDIR/debug_util.sh

if [ "$1" == "-d" ]; then
    dateOpt="--date '$2'"
    shift 2
fi

if [ "$1" == "-f" -o "$1" == "--force" ]; then
    force=1
fi

pageUrl="https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00086.html"

year=$(eval "date $dateOpt '+%Y'")
month=$(eval "date $dateOpt '+%-m'")
monthPat="(${month}|$(echo $month | ruby -ne 'puts $_.strip.tr("0123456789", "０１２３４５６７８９")'))"
url=$(RUN_CMD -f \
    "curl $pageUrl 2>/dev/null | grep -A1 '\">$year年<br' | egrep -m 1 '$monthPat月' | \
     ruby -ne 'puts \$_.scan(/(https:[^\">]*\.html)/)[0]'")

echo $url
