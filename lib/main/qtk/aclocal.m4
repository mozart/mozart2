AC_DEFUN(OZSKEL_PATH,[
  srcdir=`cd $srcdir 2> /dev/null && pwd`
  extrapath=$srcdir:`cd $srcdir/.. && pwd`:`cd $srcdir/../.. && pwd`:`cd $srcdir/../../.. && pwd`
  VAR_PATH=${srcdir}:${PATH}:${HOME}/.oz/bin:${OZHOME}/bin:/usr/local/OZSKEL/bin:/usr/local/oz/bin
  buildtop=`pwd`
  AC_SUBST(buildtop)
])

AC_DEFUN(OZSKEL_PATH_PROG, [
  if test -z "$OZSKEL_cv_$1"; then
    dummy_PWD=`pwd | sed 's/\//\\\\\//g'`
    dummy_PATH=`echo $VAR_PATH | sed -e 's/:://g'`
    dummy_PATH=`echo $dummy_PATH | sed -e "s/^\.:/$dummy_PWD:/g"`
    dummy_PATH=`echo $dummy_PATH | sed -e "s/^\.\//$dummy_PWD\//g"`
    dummy_PATH=`echo $dummy_PATH | sed -e "s/:\.\$/:$dummy_PWD/g"`
    dummy_PATH=`echo $dummy_PATH | sed -e "s/:\.:/:$dummy_PWD:/g"`
    dummy_PATH=`echo $dummy_PATH | sed -e "s/:.\//:$dummy_PWD\//g"`
    OZSKEL_for="$dummy_PATH"
    AC_PATH_PROG($1,$2,,$OZSKEL_for)
    case "$host_os" in
      cygwin32) ;;
      *) $1=`echo $$1 | sed -e "s|//|/|g"`;;
    esac
    if test ! -n "$$1"
    then
        $1=undefined
        ifelse([$3],[],[AC_MSG_ERROR([$2 not found])],$3)
    fi
    OZSKEL_cv_$1=$$1
  else
    AC_CACHE_CHECK([for $2],OZSKEL_cv_$1,true)
    $1=$OZSKEL_cv_$1
  fi
  AC_SUBST($1)])

dnl this assumes that VAR_OZE is set to the full path of the
dnl ozengine.  OZHOME is derived from it.
AC_DEFUN(OZSKEL_OZHOME,[
  if test "${OZHOME:-NONE}" = NONE; then
changequote(<,>)
    OZHOME=`expr "${VAR_OZE}" : '\(.*\)/[^/]*/[^/]*$' || echo "."`
changequote([,])
  fi
  AC_SUBST(OZHOME)
])

AC_DEFUN(OZSKEL_INSTALL,[
  if test -z "$OZSKEL_cv_INSTALL"; then
    AC_PATH_PROG(OZSKEL_cv_OZINSTALL,ozinstall,NONE,${extrapath}:${VAR_PATH})
    if test "$OZSKEL_cv_OZINSTALL" = NONE; then
      AC_MSG_ERROR([ozinstall not found])
    fi
  else
    AC_CACHE_CHECK([for ozinstall],OZSKEL_cv_OZINSTALL,true)
  fi
  VAR_OZINSTALL=$OZSKEL_cv_OZINSTALL
  AC_SUBST(VAR_OZINSTALL)
])

AC_DEFUN(OZSKEL_COMPRESS,[
  if test -z "$OZSKEL_cv_COMPRESS"; then
    AC_PATH_PROGS(OZSKEL_cv_COMPRESS,gzip compress,compress,${VAR_PATH})
  else
    AC_CACHE_CHECK([for gzip or compress],OZSKEL_cv_COMPRESS,true)
  fi
  VAR_COMPRESS=$OZSKEL_cv_COMPRESS
  AC_SUBST(VAR_COMPRESS)
])

dnl *****************************************************************
dnl windows cross compilation
dnl *****************************************************************

AC_DEFUN(OZSKEL_OZTOOL,[
  OZSKEL_PATH_PROG(VAR_OZTOOL_HOST,oztool)
  case "$target" in
    NONE)
        VAR_OZTOOL="$VAR_OZTOOL_HOST"
        ;;
    i386-mingw32)
        AC_MSG_RESULT(cross compiling for windows)
        VAR_OZTOOL="sh ${target}-oztool"
        ;;
    *)
        AC_MSG_ERROR("only known cross-compile target is i386-mingw32")
        ;;
  esac
  AC_SUBST(VAR_OZTOOL)
])

AC_DEFUN(OZSKEL_INIT,[
  AC_CANONICAL_HOST
  AC_PROG_MAKE_SET
  OZSKEL_PATH
  OZSKEL_INSTALL
  OZSKEL_COMPRESS
  OZSKEL_OZTOOL
  OZSKEL_PATH_PROG(VAR_OZC,ozc)
  OZSKEL_PATH_PROG(VAR_OZL,ozl)
  OZSKEL_PATH_PROG(VAR_OZE,ozengine)
  OZSKEL_PATH_PROG(VAR_OZH,ozh,VAR_OZH=x-ozlib://OZSKEL/ozh)
  OZSKEL_PATH_PROG(VAR_ZIP,zip,VAR_ZIP=zip)
  OZSKEL_OZHOME
])
