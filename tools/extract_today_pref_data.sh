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

#pageUrl="https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00210.html"
#pageUrl="https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00231.html"
pageUrl="https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00244.html"
year=$(eval "date $dateOpt '+%Y'")
reiwa=$(( $year - 2018))
today=$(eval "date $dateOpt '+%-m月%-d日'")


datestr=$(eval "date $dateOpt +'%Y%m%d'")
yesterday=$(date --date "$datestr yesterday" '+%Y%m%d')

pdfPath=mhlw_pdf/$datestr.pdf

VAR_PRINT year
VAR_PRINT reiwa
VAR_PRINT today
VAR_PRINT datestr
VAR_PRINT yesterday
VAR_PRINT pdfPath

echo "$(date) -- check $today"

OUTFILE=mhlw_pref/$yesterday.txt
VAR_PRINT OUTFILE

if [ -z "$force" ] && [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
    echo "Already extracted: $OUTFILE"
    exit
fi

url=$(RUN_CMD -f "curl $pageUrl 2>/dev/null | grep -m 1 '厚生労働省の対応について.*令和${reiwa}年$today' | cut -d'\"' -f2")
VAR_PRINT -f url
if [ "$url" ]; then
    #pdfUrl=$(RUN_CMD -f "curl $url 2>/dev/null | \
    #    grep -m 1 '都道府県別のPCR検査陽性者数.*${year}年$today' | cut -d'\"' -f2")
    pdfUrl=$(RUN_CMD -f "curl $url 2>/dev/null | \
        grep -m 1 'content/[0-9/]*\.pdf.*各都道府県の検査陽性者の状況' | cut -d'\"' -f2")
    VAR_PRINT -f pdfUrl
    if [ "$pdfUrl" ]; then
        [[ "$pdfUrl" == /* ]] && pdfUrl="https://www.mhlw.go.jp$pdfUrl"
        RUN_CMD -fm "curl $pdfUrl -o $pdfPath"
        RUN_CMD -fm "/usr/local/bin/docker-compose run --rm camelot | \
            sed -ne '2,/^合計/ s/ *//gp' | sed -re 's/\r//' > $OUTFILE"
        if [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
            echo "Data extracted: $OUTFILE"
            RUN_CMD -m "$BINDIR/commit-push.sh"
            echo "$(date) -- extracted $today"
            exit
        fi
    fi
fi
echo "Data not yet extracted"
