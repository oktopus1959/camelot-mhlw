#! /bin/bash

BINDIR=$(dirname $0)

. $BINDIR/debug_util.sh

myDt="$(date '+%Y/%m/%d')"
if [ "$1" == "-d" ]; then
    myDt="$(date --date '$2')"
    shift 2
fi

if [ "$1" == "-f" -o "$1" == "--force" ]; then
    force=1
fi

todayYYMMDD=$(eval "date --date '$myDt + 2018 years ago' +'%y%m%d'")
today=$(eval "date --date $myDt '+%Y%m%d'")
pdfUrl1="https://www.fukushihoken.metro.tokyo.lg.jp/index.files/${todayYYMMDD}sokuhou.pdf"
pdfUrl2="https://www.fukushihoken.metro.tokyo.lg.jp/index.files/${todayYYMMDD}sokuho.pdf"
pdfPath=work_pdf/tokyo_sokuhou_$today.pdf
OUTFILE=work_tokyo/tokyo_sokuhou_$today.txt

VAR_PRINT today
VAR_PRINT pdfPath
VAR_PRINT OUTFILE

echo "$(date) -- check $today"

if [ -z "$force" ] && [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
    echo "Already extracted: $OUTFILE"
    exit
fi

RUN_CMD -fm "mkdir -p work_pdf work_tokyo"
RUN_CMD -fm -y "curl $pdfUrl1 -o $pdfPath 2>/dev/null"
if grep '404 Not Found' $pdfPath > /dev/null; then
    RUN_CMD -fm -y "curl $pdfUrl2 -o $pdfPath 2>/dev/null"
fi

fileSize=$(wc -c < $pdfPath)
if [ -f $pdfPath ] && [ $fileSize -gt 10000 ] && ! grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm "/usr/local/bin/docker-compose \
        run --rm camelot python /root/mhlw_pref_pdf_to_text.py /$pdfPath > $OUTFILE"
    if [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
        echo "Data extracted: $OUTFILE"
        #RUN_CMD -m "$BINDIR/commit-push.sh"
        echo "$(date) -- extracted $today"
        exit
    fi
fi
echo "Data not yet extracted"
