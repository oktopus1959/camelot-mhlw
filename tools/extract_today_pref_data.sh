#! /bin/bash

BINDIR=$(dirname $0)

. $BINDIR/debug_util.sh

while [ "$1" ]; do
    case "$1" in
        -d) shift; dateOpt="--date '$1'";;
        -*day) shift; day="$1";;
        -f|--force) force=1;;
    esac
    shift
done

year=$(eval "date $dateOpt '+%Y'")
reiwa=$(( $year - 2018))
today=$(eval "date $dateOpt '+%-m月%-d日'")
[ "$day" ] || day=$(eval "date $dateOpt '+%-d'")

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

getMonthlyPageUrl() {
    local url
    if [ -f mhlw_monthly_page_url.txt ]; then
        url=$(RUN_CMD -f "cat mhlw_monthly_page_url.txt")
    fi
    if [ -z "$url" ]; then
        local rootUrl="https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00086.html"

        local year=$(eval "date $dateOpt '+%Y'")
        local month=$(eval "date $dateOpt '+%-m'")
        local monthPat="${month}|$(echo $month | ruby -ne 'puts $_.strip.tr("0123456789", "０１２３４５６７８９")')"
        local url=$(RUN_CMD -f \
            "curl $rootUrl 2>/dev/null | grep -A1 '\b$year年\b' | grep -E -m 1 '>($monthPat)月<' | \
             sed -r 's/.*(https:[^\">]*\.html).>($monthPat)月<.*/\1/'")
        [ "$url" ] && RUN_CMD -fm "echo '$url' > mhlw_monthly_page_url.txt"
    fi
    echo $url
}

#pageUrl="https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000121431_00254.html"
pageUrl=$(getMonthlyPageUrl)
VAR_PRINT pageUrl
if [ -z "$pageUrl" ]; then
    echo "Can't get monthly page url." >&2
    exit
fi

#reiwa_pat="["${reiwa}$(echo $reiwa | ruby -ne 'puts $_.strip.tr("0123456789", "０１２３４５６７８９")')"]"
#url=$(RUN_CMD -f "curl $pageUrl 2>/dev/null | grep -m 1 '厚生労働省の対応について.*令和${reiwa_pat}年$today' | cut -d'\"' -f2")
#url=$(RUN_CMD -f "curl $pageUrl 2>/dev/null | grep -m 1 '厚生労働省の対応について.*令和.*年.*月${day}日' | cut -d'\"' -f2")
url=$(RUN_CMD -f "curl $pageUrl 2>/dev/null | grep '厚生労働省の対応について.*令和' | ruby tools/zen2han.rb | grep -m 1 '令和.*年.*月${day}日' | cut -d'\"' -f2")
VAR_PRINT -f url
if [ "$url" ]; then
    if [[ "$url" == /* ]]; then
        url="https://www.mhlw.go.jp$url"
    fi
    #pdfUrl=$(RUN_CMD -f "curl $url 2>/dev/null | \
    #    grep -m 1 '都道府県別のPCR検査陽性者数.*${year}年$today' | cut -d'\"' -f2")
    pdfUrl=$(RUN_CMD -f "curl $url 2>/dev/null | \
        grep -m 1 'content/[0-9/]*\.pdf.*各都道府県の検査陽性者の状況' | cut -d'\"' -f2")
    VAR_PRINT -f pdfUrl
    if [ -z "$pdfUrl" ]; then
        pdfUrl=$(RUN_CMD -f "wget -q -O - $url 2>/dev/null | \
            grep -m 1 'content/[0-9/]*\.pdf.*各都道府県の検査陽性者の状況' | cut -d'\"' -f2")
    fi
    if [ "$pdfUrl" ]; then
        [[ "$pdfUrl" == /* ]] && pdfUrl="https://www.mhlw.go.jp$pdfUrl"
        RUN_CMD -fm "mkdir -p mhlw_pdf mhlw_pref"
        RUN_CMD -fm -y "curl $pdfUrl -o $pdfPath 2>/dev/null"
        RUN_CMD -fm "sudo docker-compose run --rm camelot | \
            sed -ne '2,/^合計/ s/ *//gp' | sed -re 's/\r//' > $OUTFILE"
        if [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
            echo "Data extracted: $OUTFILE"
            RUN_CMD -m -y "$BINDIR/commit-push.sh"
            echo "$(date) -- extracted $today"
            exit
        fi
    fi
fi
echo "Data not yet extracted"
