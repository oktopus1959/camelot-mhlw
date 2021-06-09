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

todayMMDD=$(eval "date $dateOpt '+%m%d'")
today=$(eval "date $dateOpt '+%Y%m%d'")
pdfUrl="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/kunishihyou.files/${todayMMDD}.pdf"
pdfPath=work_pdf/tokyo_iryo_$today.pdf
OUTFILE=work_tokyo/tokyo_iryo_$today.txt

VAR_PRINT today
VAR_PRINT pdfPath
VAR_PRINT OUTFILE

echo "$(date) -- check $today"

if [ -z "$force" ] && [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
    echo "Already extracted: $OUTFILE"
    exit
fi

RUN_CMD -fm "mkdir -p work_pdf work_tokyo"
RUN_CMD -fm -y "curl $pdfUrl -o $pdfPath 2>/dev/null"
fileSize=$(wc -c < $pdfPath)
if [ -f $pdfPath ] && [ $fileSize -gt 10000 ] && ! grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm "sudo docker-compose \
        run --rm camelot python /root/mhlw_pref_pdf_to_text.py /$pdfPath > $OUTFILE"
    if [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
        echo "Data extracted: $OUTFILE"
        #RUN_CMD -m "$BINDIR/commit-push.sh"
        echo "$(date) -- extracted $today"
        exit
    fi
fi
echo "Data not yet extracted"
