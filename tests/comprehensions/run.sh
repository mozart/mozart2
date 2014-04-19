#!/bin/bash
# Created by Francois Fonteyn on 02/02/2014

# Colors and styles
NORMAL="\\033[0m"
BOLD="\\033[1m"
DIM="\\033[2m"
UNDERLINE="\\033[4m"
BLINK="\\033[5m"
INVERTED="\\033[7m"
HIDDEN="\\033[8m"
BLACK="\\033[30m"
RED="\\033[31m"
GREEN="\\033[32m"
YELLOW="\\033[33m"
BLUE="\\033[34m"
MAGENTA="\\033[35m"
CYAN="\\033[36m"
LIGHT_GRAY="\\033[37m"
DARK_GRAY="\\033[90m"
LIGHT_RED="\\033[91m"
LIGHT_GREEN="\\033[92m"
LIGHT_YELLOW="\\033[93m"
LIGHT_BLUE="\\033[94m"
LIGHT_MAGENTA="\\033[95m"
LIGHT_CYAN="\\033[96m"
WHITE="\\033[97m"
BACK_BLACK="\\033[40m"
BG_RED="\\033[41m"
BG_GREEN="\\033[42m"
BG_YELLOW="\\033[43m"
BG_BLUE="\\033[44m"
BG_MAGENTA="\\033[45m"
BG_CYAN="\\033[46m"
BG_LIGHT_GRAY="\\033[47m"
BG_DARK_GRAY="\\033[100m"
BG_LIGHT_RED="\\033[101m"
BG_LIGHT_GREEN="\\033[102m"
BG_LIGHT_YELLOW="\\033[103m"
BG_LIGHT_BLUE="\\033[104m"
BG_LIGHT_MAGENTA="\\033[105m"
BG_LIGHT_CYAN="\\033[106m"
BG_WHITE="\\033[107m"

# default compile tester
cOpt=0
path=/Applications/Mozart2.app/Contents/Resources/bin
dir=$(echo "$0"|awk -F "/" '{F=""; for(A=1; A<NF; ++A) {F=F$A"/";} print(F);}')

# test one file
test_file() {
    if [ $nOpt == 0 ]; then
        echo -e "Testing \"${1}\"..."
    else
        echo -e "${BOLD}${CYAN}Testing \"${1}\"...${NORMAL}${GREEN}"
    fi
    ozc -c "${1}" -o "${1}f"
    ozengine "${1}f" ozc-x "${1}"
    rm "${1}f"
    if [ $nOpt != 0 ]; then
        echo -ne "${NORMAL}"
    fi
}

# usage
usage() {
    echo -e "${GREEN}Usage: run [-chn] [-p path] (-f file)*
    Runs all the test (.oz) files in the directory \"${dir}\"
    -c: compile the Tester.oz functor
    -n: no colors are used for the results
    -h: displays this help
    -p: to specify the mozart path (default is ${path})
    -f: test only the given file, this option can be used several times${NORMAL}"
    exit 0
}

# header
echo -e "${BOLD}${LIGHT_RED}---------------------------------------
- Author:  Francois Fonteyn, 2014     -
- This script comes with no warranty. -
---------------------------------------${NORMAL}"

# tester functor
TESTER="Tester.oz"

iF=0
nOpt=1

# Check syntax
args=`getopt chp:f:`
# Parse arguments
for((i=1;i<=$#;i++))
do
    case "${!i}" in
        -c)
            cOpt=1
            ;;
        -p)
            i=`expr $i + 1`
            path="${!i}"
            ;;
        -f)
            iF=`expr $iF + 1`
            i=`expr $i + 1`
            file[$iF]="${!i}"
            ;;
        -h)
            usage
            ;;
        -n)
            nOpt=0
            ;;
    esac
done

# export Mozart PATH
if [ ! -d "$path" ]; then
    echo -e "${RED}${BOLD}Path not found: ${path}\nPlease give a good path for Mozart.${NORMAL}"
    exit 0
fi
export PATH="$path":$PATH

# compiling Tester functor if needed
if [ $cOpt == 1 ] || [ ! -e "${dir}${TESTER}f" ]; then
    if [ $nOpt == 0 ]; then
        echo -e "Compiling Tester functor..."
    else
        echo -e "${BOLD}${CYAN}Compiling Tester functor...${NORMAL}${RED}"
    fi
    ozc -c "${dir}$TESTER" -o "${dir}${TESTER}f"
    if [ $nOpt == 0 ]; then
        echo "Done"
    else
        echo -e "${GREEN}Done${NORMAL}"
    fi
fi

# test files if given
if [ $iF -gt 0 ]
then
    for((i=1;i<=$iF;i++))
    do
        test_file "${file[$i]}"
    done
    rm "${dir}${TESTER}f"
    exit 0
fi

# looping in folder
cd "$dir"
for x in *; do
    if [ "$x" == "$TESTER" ]; then
        continue
    fi
    # get extension
    ext=$(echo "$x" | awk -F "." '{print $NF}')
    # check if oz file
    if [ "$ext" == "oz" ]; then
        test_file "$x"
    fi
done

if [ -e "${dir}${TESTER}f" ]; then
    rm "${dir}${TESTER}f"
fi

echo -ne "${NORMAL}"
