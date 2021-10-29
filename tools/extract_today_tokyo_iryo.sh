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

baseUrl="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/corona_portal/info"
pdfFile=$(curl $baseUrl/kunishihyou.html 2>/dev/null | egrep "filelink.*${todayMMDD}.*国のステージ判断のための指標" | sed -rn 's/^.* href="([^"]+)" .*$/\1/p')

[ "$pdfFile" ] && pdfUrl0=$baseUrl/$pdfFile

pdfUrl11="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/corona_portal/info/kunishihyou.files/kuni${todayMMDD}.pdf"
pdfUrl12="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/corona_portal/info/kunishihyou.files/${todayMMDD}kuni.pdf"
pdfUrl2="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/corona_portal/info/kunishihyou.files/${todayMMDD}.pdf"
pdfUrl31="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/kunishihyou.files/kuni${todayMMDD}.pdf"
pdfUrl32="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/kunishihyou.files/${todayMMDD}kuni.pdf"
pdfUrl4="https://www.fukushihoken.metro.tokyo.lg.jp/iryo/kansen/kunishihyou.files/${todayMMDD}.pdf"
pdfPath=work_pdf/tokyo_iryo_$today.pdf
pdfPathRemote=${pdfPath/work/tokyo}
OUTFILE=work_tokyo/tokyo_iryo_$today.txt

VAR_PRINT today
VAR_PRINT pdfUrl0
VAR_PRINT pdfPath
VAR_PRINT pdfPathRemote
VAR_PRINT OUTFILE

echo "$(date) -- check $today"

if [ -z "$force" ] && [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
    echo "Already extracted: $OUTFILE"
    exit
fi

RUN_CMD -fm "mkdir -p work_pdf work_tokyo"
RUN_CMD -fm -y "curl $pdfUrl0 -o $pdfPath 2>/dev/null"
fileSize=$(wc -c < $pdfPath)
if [ ! -f $pdfPath ] || [ $fileSize -lt 10000 ] || grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm -y "curl $pdfUrl11 -o $pdfPath 2>/dev/null"
    fileSize=$(wc -c < $pdfPath)
fi
if [ ! -f $pdfPath ] || [ $fileSize -lt 10000 ] || grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm -y "curl $pdfUrl12 -o $pdfPath 2>/dev/null"
    fileSize=$(wc -c < $pdfPath)
fi
if [ ! -f $pdfPath ] || [ $fileSize -lt 10000 ] || grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm -y "curl $pdfUrl2 -o $pdfPath 2>/dev/null"
    fileSize=$(wc -c < $pdfPath)
fi
if [ ! -f $pdfPath ] || [ $fileSize -lt 10000 ] || grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm -y "curl $pdfUrl31 -o $pdfPath 2>/dev/null"
    fileSize=$(wc -c < $pdfPath)
fi
if [ ! -f $pdfPath ] || [ $fileSize -lt 10000 ] || grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm -y "curl $pdfUrl32 -o $pdfPath 2>/dev/null"
    fileSize=$(wc -c < $pdfPath)
fi
if [ ! -f $pdfPath ] || [ $fileSize -lt 10000 ] || grep '404 Not Found' $pdfPath ; then
    RUN_CMD -fm -y "curl $pdfUrl4 -o $pdfPath 2>/dev/null"
    fileSize=$(wc -c < $pdfPath)
fi
if [ -f $pdfPath ] && [ $fileSize -gt 10000 ] && ! grep '404 Not Found' $pdfPath ; then
    # RUN_CMD -fm "sudo docker-compose run --rm camelot python /root/mhlw_pref_pdf_to_text.py /$pdfPath > $OUTFILE"
    RUN_CMD -fm "cat $pdfPath | ssh 192.168.1.162 'cat > $pdfPathRemote; pdf2txt.py $pdfPathRemote' | \
        sed -rn 's/^（([0-9,]*)人\/1,207床）.*$/\1/p' | sed -r 's/,//g' | head -1 > $OUTFILE"

    if [ -f $OUTFILE ] && [ -s $OUTFILE ]; then
        echo "Data extracted: $OUTFILE"
        #RUN_CMD -m "$BINDIR/commit-push.sh"
        echo "$(date) -- extracted $today"
        exit
    fi
fi
echo "Data not yet extracted"
