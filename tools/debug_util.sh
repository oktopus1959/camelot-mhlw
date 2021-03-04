#! /bin/bash

# This script is a free software.
# You may freely use, distribute and/or modify it.

# デバッグ出力先
exec 7>&2

# レベル
if [ "$__DEBUG_UTIL_INDENT" ]; then
    export __DEBUG_UTIL_INDENT+='  '
else
    export __DEBUG_UTIL_INDENT='X'
fi

# 変数
__DEBUG=0
__DRYRUN=0
__MSGRUN=0
__NOMSGRUN=0
__NOCOLOR=0
__USAGE=0
__TEST_MODE=0
#__LOGFILE=		# このスクリプトを source する前に __LOGFILE を設定しておいてもよい
__SUPERLOG=0

# My usage
__debug_util_usage() {
    cat <<EOS >&7

  For DEBUG: $(basename $0) [DEBUG-OPTS...] [---] [APP-OPTS...] APP-ARGS...
      DEBUG-OPTS:
        --debhelp,      --debughelp:        show this help.
        --deb,          --debug:            Run program in debug mode.
        --dry,          --dryrun:           Run program in dry-run mode.
        --msg,          --msgrun:           Forcedly set msg-run mode ON.
        --nomsg,        --nomsgrun:         Forcedly set msg-run mode OFF.
        --nocol,        --nocolor:          No color mode.
        --deglog,       --debuglog:         Save debug msg in 'log/$(basename $0).log'
        --deblog=FILE,  --debuglog=FILE     Save debug msg in FILE.
        -h, --help,     --usage:            Let __USAGE=1.
        --test:                             Let __TEST_MODE=1.

      Available function:
        DEBUG_PRINT  [-f|-m]  MSGS...
        VAR_PRINT    [-f|-m]  MSGS...
        BANNER_PRINT [-m][-e] TAG
        YELLOW_PRINT [-n]     PREFIX MSGS...
        RED_PRINT           < STDIN
        RUN_CMD [-f|-m|-n|-b] CMD-LINE
EOS
    exit 1
}

# option parsing
restArgs=()
while [ "$1" ]; do
    case "$1" in
    --deb*help* ) __debug_util_usage ;;
    --deb*log*=* ) __LOGFILE="${1#*=}" ;;
    --deb*log* ) __LOGFILE="log/$(basename $0).log" ;;
    --superlog ) __SUPERLOG=1 ;;
    --deb*  ) __DEBUG=1; __MSGRUN=1; __DEBUG_FLAG=--debug ;;
    --dry*  ) __DRYRUN=1; __MSGRUN=1; __DRYRUN_FLAG=--dryrun ;;
    --msg*  ) __MSGRUN=1; __MSGRUN_FLAG=--msgrun ;;
    --nomsg*) __NOMSGRUN=1 ;;
    --nocol*) __NOCOLOR=1 ;;
    -h|--help|--usage) __USAGE=1; declare -F usage >/dev/null && usage ;;
    --test  ) __TEST_MODE=1 ;;
    * ) restArgs+=("$1") ;;
    esac
    shift
done
# 残りの引数を $1 ～ に再セットする
set -- "${restArgs[@]}" "$@"

# フラグをまとめる
__DEBUG_FLAGS=""
[ "$__DEBUG_FLAG" ] && __DEBUG_FLAGS="$__DEBUG_FLAG"
if [ "$__DRYRUN_FLAG" ]; then
    [ "$__DEBUG_FLAGS" ] && __DEBUG_FLAGS+=" "
    __DEBUG_FLAGS+="$__DRYRUN_FLAG"
fi
if [ "$__MSGRUN_FLAG" ]; then
    [ "$__DEBUG_FLAGS" ] && __DEBUG_FLAGS+=" "
    __DEBUG_FLAGS+="$__MSGRUN_FLAG"
fi
if [ "$__LOGFILE" ]; then
    [ "$__DEBUG_FLAGS" ] && __DEBUG_FLAGS+=" "
    __DEBUG_FLAGS+="--deblog=$__LOGFILE --superlog"
fi
__DEBUG_OPTS="$__DEBUG_FLAGS"

# 黄色で標準エラー出力
__YELLOW_PRINT() {
    local prefix="$1"
    shift
    local color="33"
    [ "$prefix" == "RUN:" ] && color="32"                 # RUN: は緑にする
    local colorBegin=$'\e'\[${color}m
    local colorEnd=$'\e'\[0m
    if [ $__NOCOLOR -eq 1 ]; then
        colorBegin=''
        colorEnd=''
    fi
    local indent=${__DEBUG_UTIL_INDENT/X/}
    [ $__msgrun -eq 1 ] && echo "${indent}${colorBegin}${prefix}${colorEnd} $@" >&7
    [ "$__LOGFILE" -a $__SUPERLOG -eq 0 ] && echo "${indent}${prefix}" "$@" >> $__LOGFILE
    sleep 0.02
}

YELLOW_PRINT() {
    __msgrun=1
    if [ "$1" == "-n" ]; then
        __msgrun=0
        shift
    fi
    __YELLOW_PRINT "$@"
}

# コマンドの標準エラー出力のうち、表示を抑止するパターン
[ "$__FILTER_PATTERN" ] || __FILTER_PATTERN=^$'\001'$'\002'$'\003'
# コマンドの標準エラー出力のうち、表示を黄色にするパターン
[ "$__YELLOW_PATTERN" ] || __YELLOW_PATTERN=^$'\001'$'\002'$'\003'

# 標準入力から読み込んだ文字列を赤色で標準エラーに出力する
RED_PRINT() {
    which perl > /dev/null 2>&1
    local hasPerl=$?
    local logfile=$__LOGFILE
    [ "$logfile" -a $__SUPERLOG -eq 0 ] || logfile=/dev/null
    local pattern=$'\033'"\[[0-9]*m"
    egrep --line-buffered -v "$__FILTER_PATTERN" | tee -a >(sed "s/$pattern//g" >> $logfile) | \
    if [ $hasPerl -eq 0 -a $__NOCOLOR -eq 0 ]; then
        LC_ALL=C perl -e '$|=1; while(<>){chomp; if(/'"$__YELLOW_PATTERN"'/){print "\033[33m".$_."\033[0m\n";}else{print "\033[31m".$_."\033[0m\n";}}'
    else
        cat
    fi >&7
}

# バナー表示
# $1 : 文言
BANNER_PRINT() {
    __msgrun=1
    if [ "$1" == "-n" ]; then
        __msgrun=$__MSGRUN
        shift
    elif [ "$1" == "-m" ]; then
        __msgrun=1
        shift
    fi
    [ $__msgrun -eq 0 ] || __msgrun=$((1 - $__NOMSGRUN))
    sleep 0.2
    if [ "$1" == "-e" ]; then
        __YELLOW_PRINT "======== [$(basename $0)] $2 @ $(date +'%Y/%m/%d %H:%M:%S') ========"
    else
        __YELLOW_PRINT "---- $1 @ $(date +'%Y/%m/%d %H:%M:%S') ----"
    fi
}

# DEBUG_PRINT
# -f : 強制出力
# -1 : 標準出力
DEBUG_PRINT() {
    local dbgprn=$__DEBUG
    if [[ "$1" == -[fm] ]]; then
        dbgprn=1
        shift
    fi
    if [ $dbgprn -ne 0 ]; then
        if [ "$1" == "-1" ]; then
            # 標準出力へのエコー
            shift
            echo "${__DEBUG_UTIL_INDENT/X/}DBG: $@"
        else
            # デフォルトはエラー出力へのエコー
            __msgrun=$((1 - $__NOMSGRUN))
            __YELLOW_PRINT "DBG:" "$@"
        fi
    fi
}

# VAR_PRINT
# -f : 強制出力
# -1 : 標準出力
VAR_PRINT() {
    local dbgprn=$__DEBUG
    if [[ "$1" == -[fm] ]]; then
        dbgprn=1
        shift
    fi
    if [ $dbgprn -ne 0 ]; then
        if [ "$1" == "-1" ]; then
            # 標準出力へのエコー
            shift
            echo "${__DEBUG_UTIL_INDENT/X/}VAR: $1=${!1}"
        else
            # デフォルトはエラー出力へのエコー
            __msgrun=$((1 - $__NOMSGRUN))
            __YELLOW_PRINT "VAR:" "$1=${!1}"
        fi
    fi
}

# RUN_CMD
RUN_CMD() {
    local dryrun=$__DRYRUN
    local nomsg=$__NOMSGRUN
    local bgrun=0
    local yellow=0
    local direct=0
    local prefix='RUN'
    local cmdline=''
    __msgrun=$__MSGRUN

    while [[ "$1" == -* ]]; do
        case "$1" in
          -fm | -mf) __msgrun=1; dryrun=0 ;;
          -m* ) __msgrun=1 ;;     # 実行するコマンドラインを常にエコーする
          -f* ) dryrun=0 ;;       # DRYRUNモードであっても強制的に実行する
          -n* ) nomsg=1 ;;        # DEBUGモード場合にかぎり、コマンドラインエコーを行う
          -b* ) bgrun=1 ;;        # バックグラウンドで実行
          -y* ) yellow=1 ;;       # 黄色表示
          -d* ) direct=1 ;;       # 赤色表示なし
        esac
        shift
    done

    [ $nomsg -eq 1 -a $__MSGRUN -eq 0 ] && __msgrun=0

    [ $dryrun -ne 0 ] && prefix='DRY'

    cmdline="$1"
    shift
    while [ "$1" ]; do
        # 引数に ; | & を含み、かつ、空白または ' を含まない場合は、' で囲む
        if [[ "$1" == *[\;\|\&]* && "$1" != *[\'\ ]* ]]; then
            cmdline+=" '$1'"
        else
            cmdline+=" $1"
        fi
        shift
    done

    __YELLOW_PRINT "$prefix:" "$(echo $cmdline | sed 's/   */ /g')"

    if [ $dryrun -eq 0 ]; then
        if [ $bgrun -ne 0 ]; then
          eval "$cmdline" &
        elif [ $direct -eq 1 ]; then
          eval "$cmdline"
        elif [ $yellow -eq 1 ]; then
          local __yellow_pattern="$__YELLOW_PATTERN"
          __YELLOW_PATTERN=.
          eval "$cmdline" 2> >(RED_PRINT)
          __YELLOW_PATTERN="__yellow_pattern"
        else
          eval "$cmdline" 2> >(RED_PRINT)
        fi
    fi
}

# .back ファイルを 1～9 まで保存
# $1: オリジナルファイルパス
SAVE_BACK_FILE() {
    local runFlag=''
    if [[ "$1" == -* ]]; then
        runFlag=$1
        shift
    fi
    local origPath=$1
    local origDir=$(dirname $origPath)
    [ "$origDir" ] || origDir=.
    local origFile=$(basename $origPath)
    local backDir=$origDir/back
    local backPath=$backDir/$origFile.back
    mkdir -p $backDir
    if [ -s $backPath ]; then
        for x in 8 7 6 5 4 3 2 1; do
            [ -f ${backPath}$x ] && RUN_CMD $runFlag "mv -f ${backPath}$x ${backPath}$((x + 1))"
        done
        RUN_CMD $runFlag "mv -f $backPath ${backPath}1"
    fi
    [ -f $origPath ] && RUN_CMD $runFlag "mv -f $origPath $backPath"
}

# ログファイル指定あり
if [ "$__LOGFILE" ]; then
    if [ ! -f "$__LOGFILE" ]; then
        mkdir -p $(dirname $__LOGFILE); touch $__LOGFILE
        __msgrun=$((1 - $__NOMSGRUN))
        __YELLOW_PRINT "mkdir -p $(dirname $__LOGFILE); touch $__LOGFILE"
    fi
    if [ $__MSGRUN -eq 1 -a $__NOMSGRUN -eq 0 ]; then
        VAR_PRINT -f __LOGFILE
    fi
fi

