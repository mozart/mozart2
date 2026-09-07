#!/bin/sh

# where Oz resides:

howcalled="$0"
cmd=`basename "$howcalled"`

if test -z "${OZHOME}"
then
  dir=`dirname "$howcalled"`
  OZHOME=`(cd "$dir"; cd ..; pwd)`
fi
export OZHOME

# Determine OZEMACS

if test -z "${OZEMACS}"
then
    IFS="${IFS=   }"; saveifs="$IFS"; IFS="$IFS:"
    for name in emacs xemacs lemacs; do
        for dir in $PATH; do
            test -z "$dir" && dir=.
            if test -f $dir/$name; then
                # Not all systems have dirname.
                OZEMACS=$dir/$name
                break 2
            fi
        done
    done
    IFS="$saveifs"
    if test -z "${OZEMACS}"
    then
        echo "Cannot find emacs" 1>&2
        echo "Try setting environment variable OZEMACS" 1>&2
        exit 1
    fi
fi

# Call OZEMACS

if ( "$OZEMACS" --version | grep XEmacs > /dev/null 2>&1 )
then
    exec "$OZEMACS" \
            --eval '(setq load-path (cons "'$OZHOME'/share/mozart/elisp" load-path))' \
            -l oz.elc -f run-oz "$@"
else
    exec "$OZEMACS" -L "$OZHOME/share/mozart/elisp" -l oz.elc -f run-oz "$@"
fi
